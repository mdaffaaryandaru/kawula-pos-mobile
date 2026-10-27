import '../../../auth/domain/entities/auth_user.dart';

abstract interface class UserManagementRepository {
  Future<List<AuthUser>> getUsers();

  Future<AuthUser> updatePin({required String userId, required String pin});
}
