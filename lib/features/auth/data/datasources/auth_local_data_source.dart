// Package imports:
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  static const _tokenKey = 'access_token';
  static const _verifiedCashierUserIdKey = 'verified_cashier_user_id';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<String?> readVerifiedCashierUserId() =>
      _storage.read(key: _verifiedCashierUserIdKey);

  Future<void> saveVerifiedCashierUserId(String userId) =>
      _storage.write(key: _verifiedCashierUserIdKey, value: userId);

  Future<void> clearVerifiedCashierUserId() =>
      _storage.delete(key: _verifiedCashierUserIdKey);
}
