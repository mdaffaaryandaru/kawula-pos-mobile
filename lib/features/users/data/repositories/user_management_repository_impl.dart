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
}
