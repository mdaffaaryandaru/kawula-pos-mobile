// Project imports:
import 'package:kawula_pos/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kawula_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/auth_session_expiry_handler.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource, {
    this.sessionExpiryHandler,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final AuthSessionExpiryHandler? sessionExpiryHandler;

  @override
  Future<AuthUser?> restoreSession() async {
    final token = await _localDataSource.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await _remoteDataSource.getProfile(token);
      sessionExpiryHandler?.markSessionActive(token);
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _localDataSource.deleteToken();
        sessionExpiryHandler?.markSessionEnded(token);
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    sessionExpiryHandler?.markSessionEnded();
    final token = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    await _localDataSource.saveToken(token);
    try {
      final user = await _remoteDataSource.getProfile(token);
      sessionExpiryHandler?.markSessionActive(token);
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _localDataSource.deleteToken();
        sessionExpiryHandler?.markSessionEnded(token);
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() {
    sessionExpiryHandler?.markSessionEnded();
    return _localDataSource.deleteToken();
  }
}
