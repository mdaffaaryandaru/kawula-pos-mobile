import '../../../../framework/core/exceptions/api_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_user.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<AuthUser?> restoreSession() async {
    final token = await _localDataSource.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      return await _remoteDataSource.getProfile(token);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _localDataSource.deleteToken();
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
    final token = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    await _localDataSource.saveToken(token);
    try {
      return await _remoteDataSource.getProfile(token);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _localDataSource.deleteToken();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() => _localDataSource.deleteToken();
}
