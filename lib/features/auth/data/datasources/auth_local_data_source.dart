// Package imports:
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  static const _tokenKey = 'access_token';
  static const _verifiedOfflineSalesUserIdKey =
      'verified_offline_sales_user_id';
  static const _legacyVerifiedCashierUserIdKey = 'verified_cashier_user_id';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<String?> readVerifiedCashierUserId() async {
    final verifiedUserId = await _storage.read(
      key: _verifiedOfflineSalesUserIdKey,
    );
    return verifiedUserId ??
        await _storage.read(key: _legacyVerifiedCashierUserIdKey);
  }

  Future<void> saveVerifiedCashierUserId(String userId) =>
      _storage.write(key: _verifiedOfflineSalesUserIdKey, value: userId);

  Future<void> clearVerifiedCashierUserId() async {
    await _storage.delete(key: _verifiedOfflineSalesUserIdKey);
    await _storage.delete(key: _legacyVerifiedCashierUserIdKey);
  }
}
