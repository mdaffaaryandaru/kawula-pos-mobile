import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/repositories/user_management_repository.dart';

sealed class UserManagementState {
  const UserManagementState();
}

final class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

final class UserManagementLoaded extends UserManagementState {
  const UserManagementLoaded(this.users, {this.errorMessage});

  final List<AuthUser> users;
  final String? errorMessage;
}

final class UserManagementFailure extends UserManagementState {
  const UserManagementFailure(this.message);

  final String message;
}

class UserManagementCubit extends Cubit<UserManagementState> {
  UserManagementCubit(this._repository) : super(const UserManagementLoading());

  final UserManagementRepository _repository;

  Future<void> load() async {
    emit(const UserManagementLoading());
    try {
      final users = await _repository.getUsers();
      emit(UserManagementLoaded(users));
    } catch (error) {
      emit(UserManagementFailure(_messageFor(error)));
    }
  }

  Future<void> updatePin({required String userId, required String pin}) async {
    final currentState = state;
    if (currentState is! UserManagementLoaded) return;
    try {
      final updatedUser = await _repository.updatePin(userId: userId, pin: pin);
      final users = currentState.users
          .map((user) => user.id == userId ? updatedUser : user)
          .toList(growable: false);
      emit(UserManagementLoaded(users));
    } catch (error) {
      emit(
        UserManagementLoaded(
          currentState.users,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<bool> saveUser({
    String? userId,
    required String name,
    required String email,
    required String password,
    required String pin,
    required String role,
  }) async {
    final currentState = state;
    if (currentState is! UserManagementLoaded) return false;
    try {
      final saved = await _repository.saveUser(
        userId: userId,
        name: name,
        email: email,
        password: password,
        pin: pin,
        role: role,
      );
      final users = userId == null
          ? [saved, ...currentState.users]
          : currentState.users
                .map((user) => user.id == userId ? saved : user)
                .toList(growable: false);
      emit(UserManagementLoaded(users));
      return true;
    } catch (error) {
      emit(
        UserManagementLoaded(
          currentState.users,
          errorMessage: _messageFor(error),
        ),
      );
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    final currentState = state;
    if (currentState is! UserManagementLoaded) return false;
    try {
      await _repository.deleteUser(userId);
      emit(
        UserManagementLoaded(
          currentState.users
              .where((user) => user.id != userId)
              .toList(growable: false),
        ),
      );
      return true;
    } catch (error) {
      emit(
        UserManagementLoaded(
          currentState.users,
          errorMessage: _messageFor(error),
        ),
      );
      return false;
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
