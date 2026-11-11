import 'dart:async';

import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kawula_pos/features/auth/data/models/auth_user_model.dart';
import 'package:kawula_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/auth_session_expiry_handler.dart';
import 'package:kawula_pos/framework/core/network/platform_network_exception.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource, {
    this.sessionExpiryHandler,
    this.masterDataCache,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final AuthSessionExpiryHandler? sessionExpiryHandler;
  final CashierMasterDataCache? masterDataCache;

  @override
  Future<AuthUser?> restoreSession() async {
    final token = await _localDataSource.readToken();
    if (token == null || token.isEmpty) {
      await _localDataSource.clearVerifiedCashierUserId();
      return null;
    }

    final AuthUser user;
    try {
      user = await _remoteDataSource.getProfile(token);
    } on ApiException catch (error) {
      if (error.statusCode != null && error.statusCode! < 500) {
        masterDataCache?.markOnline();
      } else {
        masterDataCache?.markOffline();
      }
      if (error.statusCode == 401) {
        await _localDataSource.clearVerifiedCashierUserId();
        await _localDataSource.deleteToken();
        sessionExpiryHandler?.markSessionEnded(token);
        return null;
      }
      if (error.statusCode == 403) {
        await _localDataSource.clearVerifiedCashierUserId();
      }
      rethrow;
    } on http.ClientException {
      masterDataCache?.markOffline();
      return _restoreOfflineCashierSession(token);
    } on TimeoutException {
      masterDataCache?.markOffline();
      return _restoreOfflineCashierSession(token);
    } on Exception catch (error) {
      if (!isPlatformNetworkException(error)) rethrow;
      masterDataCache?.markOffline();
      return _restoreOfflineCashierSession(token);
    }

    await _saveVerifiedProfile(user);
    sessionExpiryHandler?.markSessionActive(token);
    return user;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    sessionExpiryHandler?.markSessionEnded();
    await _localDataSource.clearVerifiedCashierUserId();
    final token = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    await _localDataSource.saveToken(token);
    try {
      final user = await _remoteDataSource.getProfile(token);
      await _saveVerifiedProfile(user);
      sessionExpiryHandler?.markSessionActive(token);
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _localDataSource.clearVerifiedCashierUserId();
        await _localDataSource.deleteToken();
        sessionExpiryHandler?.markSessionEnded(token);
      } else if (error.statusCode == 403) {
        await _localDataSource.clearVerifiedCashierUserId();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    sessionExpiryHandler?.markSessionEnded();
    await _localDataSource.clearVerifiedCashierUserId();
    await _localDataSource.deleteToken();
  }

  Future<void> _saveVerifiedProfile(AuthUser user) async {
    final cache = masterDataCache;
    if (!canUseOfflineSales(user.role) || cache == null) {
      await _localDataSource.clearVerifiedCashierUserId();
      return;
    }

    await cache.saveCashierProfile(
      userId: user.id,
      role: user.role,
      payload: AuthUserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        hasPin: user.hasPin,
      ).toJson(),
    );
    await _localDataSource.saveVerifiedCashierUserId(user.id);
    masterDataCache?.markOnline();
  }

  Future<AuthUser?> _restoreOfflineCashierSession(String token) async {
    final verifiedUserId = await _localDataSource.readVerifiedCashierUserId();
    if (verifiedUserId == null || verifiedUserId.trim().isEmpty) return null;

    final cached = await masterDataCache?.readCashierProfile(verifiedUserId);
    if (cached is! Map<String, dynamic>) return null;
    final user = AuthUserModel.fromJson(cached);
    if (user.id != verifiedUserId || !canUseOfflineSales(user.role)) {
      return null;
    }

    sessionExpiryHandler?.markSessionActive(token);
    return AuthUser(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      hasPin: user.hasPin,
      isOfflineSession: true,
    );
  }
}
