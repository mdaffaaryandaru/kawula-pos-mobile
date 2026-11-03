// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> restoreSession();

  Future<AuthUser> login({required String email, required String password});

  Future<void> logout();
}
