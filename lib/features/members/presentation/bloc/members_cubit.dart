import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/member.dart';
import '../../domain/entities/membership_program.dart';
import '../../domain/repositories/members_repository.dart';

sealed class MembersState {
  const MembersState();
}

final class MembersLoading extends MembersState {
  const MembersLoading();
}

final class MembersLoaded extends MembersState {
  const MembersLoaded({
    required this.members,
    required this.program,
    this.errorMessage,
  });

  final List<Member> members;
  final MembershipProgram program;
  final String? errorMessage;
}

final class MembersFailure extends MembersState {
  const MembersFailure(this.message);

  final String message;
}

class MembersCubit extends Cubit<MembersState> {
  MembersCubit(this._repository) : super(const MembersLoading());

  final MembersRepository _repository;

  Future<void> load() async {
    emit(const MembersLoading());
    try {
      final members = await _repository.getMembers();
      final program = await _repository.getMembershipProgram();
      emit(MembersLoaded(members: members, program: program));
    } catch (error) {
      emit(MembersFailure(_messageFor(error)));
    }
  }

  Future<bool> createMember({
    required String name,
    required String phoneNumber,
    required String email,
  }) async {
    try {
      await _repository.createMember(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
      );
      await load();
      return state is MembersLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> updateMember({
    required String memberId,
    required String name,
    required String phoneNumber,
    required String email,
    required bool isActive,
  }) async {
    try {
      await _repository.updateMember(
        memberId: memberId,
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        isActive: isActive,
      );
      await load();
      return state is MembersLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> deleteMember(String memberId) async {
    try {
      await _repository.deleteMember(memberId);
      await load();
      return state is MembersLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is MembersLoaded) {
      emit(
        MembersLoaded(
          members: currentState.members,
          program: currentState.program,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(MembersFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
