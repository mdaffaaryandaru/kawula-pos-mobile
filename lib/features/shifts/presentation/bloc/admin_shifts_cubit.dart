import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/active_shift.dart';
import '../../domain/entities/admin_shift_detail.dart';
import '../../domain/repositories/admin_shifts_repository.dart';

sealed class AdminShiftsState {
  const AdminShiftsState();
}

final class AdminShiftsLoading extends AdminShiftsState {
  const AdminShiftsLoading();
}

final class AdminShiftsLoaded extends AdminShiftsState {
  const AdminShiftsLoaded({
    required this.shifts,
    required this.statusFilter,
    this.errorMessage,
  });

  final List<ActiveShift> shifts;
  final String? statusFilter;
  final String? errorMessage;
}

final class AdminShiftsFailure extends AdminShiftsState {
  const AdminShiftsFailure(this.message);

  final String message;
}

class AdminShiftsCubit extends Cubit<AdminShiftsState> {
  AdminShiftsCubit(this._repository) : super(const AdminShiftsLoading());

  final AdminShiftsRepository _repository;

  Future<void> load({String? status}) async {
    emit(const AdminShiftsLoading());
    try {
      emit(
        AdminShiftsLoaded(
          shifts: await _repository.getShifts(status: status),
          statusFilter: status,
        ),
      );
    } catch (error) {
      emit(AdminShiftsFailure(_messageFor(error)));
    }
  }

  Future<AdminShiftDetail?> getDetail(String shiftId) async {
    try {
      return await _repository.getShiftDetail(shiftId);
    } catch (error) {
      _setOperationError(error);
      return null;
    }
  }

  Future<bool> forceClose({
    required String shiftId,
    required num actualCash,
    required String notes,
  }) async {
    final currentState = state;
    try {
      await _repository.forceCloseShift(
        shiftId: shiftId,
        actualCash: actualCash,
        notes: notes,
      );
      await load(
        status: currentState is AdminShiftsLoaded
            ? currentState.statusFilter
            : null,
      );
      return state is AdminShiftsLoaded;
    } catch (error) {
      _setOperationError(error);
      return false;
    }
  }

  void _setOperationError(Object error) {
    final currentState = state;
    final message = _messageFor(error);
    if (currentState is AdminShiftsLoaded) {
      emit(
        AdminShiftsLoaded(
          shifts: currentState.shifts,
          statusFilter: currentState.statusFilter,
          errorMessage: message,
        ),
      );
    } else {
      emit(AdminShiftsFailure(message));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
