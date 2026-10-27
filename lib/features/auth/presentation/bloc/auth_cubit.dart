import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthChecking());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    emit(const AuthChecking());
    try {
      final user = await _repository.restoreSession();
      emit(
        user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
      );
    } catch (error) {
      emit(AuthSessionFailure(_messageFor(error)));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthSubmitting());
    try {
      final user = await _repository.login(
        email: email.trim(),
        password: password,
      );
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthUnauthenticated(errorMessage: _messageFor(error)));
    }
  }

  Future<void> logout() async {
    emit(const AuthChecking());
    try {
      await _repository.logout();
      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(AuthSessionFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
