import '../../domain/entities/auth_user.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthChecking extends AuthState {
  const AuthChecking();
}

final class AuthSubmitting extends AuthState {
  const AuthSubmitting();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage});

  final String? errorMessage;
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;
}

final class AuthSessionFailure extends AuthState {
  const AuthSessionFailure(this.message);

  final String message;
}
