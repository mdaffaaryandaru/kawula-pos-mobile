// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawula_pos/framework/core/network/auth_session_expiry_handler.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository, {this.sessionExpiryHandler})
    : super(const AuthChecking()) {
    sessionExpiryHandler?.attach(_expireSession);
  }

  final AuthRepository _repository;
  final AuthSessionExpiryHandler? sessionExpiryHandler;
  int _operationGeneration = 0;

  Future<void> restoreSession() async {
    final generation = ++_operationGeneration;
    emit(const AuthChecking());
    try {
      final user = await _repository.restoreSession();
      if (generation != _operationGeneration) return;
      emit(
        user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
      );
    } catch (error) {
      if (generation != _operationGeneration) return;
      emit(AuthSessionFailure(_messageFor(error)));
    }
  }

  Future<void> login({required String email, required String password}) async {
    final generation = ++_operationGeneration;
    emit(const AuthSubmitting());
    try {
      final user = await _repository.login(
        email: email.trim(),
        password: password,
      );
      if (generation != _operationGeneration) return;
      emit(AuthAuthenticated(user));
    } catch (error) {
      if (generation != _operationGeneration) return;
      emit(AuthUnauthenticated(errorMessage: _messageFor(error)));
    }
  }

  Future<void> logout() async {
    ++_operationGeneration;
    sessionExpiryHandler?.markSessionEnded();
    emit(const AuthChecking());
    try {
      await _repository.logout();
      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(AuthSessionFailure(_messageFor(error)));
    }
  }

  Future<void> _expireSession() async {
    ++_operationGeneration;
    sessionExpiryHandler?.markSessionEnded();
    emit(const AuthChecking());
    try {
      await _repository.logout();
      emit(
        const AuthUnauthenticated(
          errorMessage: 'Sesi telah berakhir. Silakan login kembali.',
        ),
      );
    } catch (error) {
      emit(AuthSessionFailure(_messageFor(error)));
    }
  }

  @override
  Future<void> close() {
    sessionExpiryHandler?.detach();
    return super.close();
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
