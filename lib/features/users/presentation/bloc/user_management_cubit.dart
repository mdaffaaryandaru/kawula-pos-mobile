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

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
