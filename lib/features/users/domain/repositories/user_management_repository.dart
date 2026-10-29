import '../../../auth/domain/entities/auth_user.dart';

abstract interface class UserManagementRepository {
  Future<List<AuthUser>> getUsers();

  Future<AuthUser> updatePin({required String userId, required String pin});

  Future<AuthUser> saveUser({
    String? userId,
    required String name,
    required String email,
    required String password,
    required String pin,
    required String role,
  });

  Future<void> deleteUser(String userId);
}
