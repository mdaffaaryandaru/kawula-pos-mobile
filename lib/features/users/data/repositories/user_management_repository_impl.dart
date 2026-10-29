import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../datasources/users_remote_data_source.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  const UserManagementRepositoryImpl(this._remoteDataSource);

  final UsersRemoteDataSource _remoteDataSource;

  @override
  Future<List<AuthUser>> getUsers() => _remoteDataSource.getUsers();

  @override
  Future<AuthUser> updatePin({required String userId, required String pin}) {
    return _remoteDataSource.updatePin(userId: userId, pin: pin);
  }

  @override
  Future<AuthUser> saveUser({
    String? userId,
    required String name,
    required String email,
    required String password,
    required String pin,
    required String role,
  }) => _remoteDataSource.saveUser(
    userId: userId,
    name: name,
    email: email,
    password: password,
    pin: pin,
    role: role,
  );

  @override
  Future<void> deleteUser(String userId) =>
      _remoteDataSource.deleteUser(userId);
}
