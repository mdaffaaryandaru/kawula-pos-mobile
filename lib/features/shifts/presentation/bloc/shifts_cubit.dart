import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/shifts_repository.dart';
import 'shifts_state.dart';

class ShiftsCubit extends Cubit<ShiftsState> {
  ShiftsCubit(this._repository) : super(const ShiftsLoading());

  final ShiftsRepository _repository;

  Future<void> loadActive() async {
    emit(const ShiftsLoading());
    try {
      final shift = await _repository.getActive();
      if (shift != null) {
        emit(ShiftsActive(shift));
        return;
      }
      final availability = await _repository.getCashAvailability();
      emit(ShiftsNeedsOpening(availability));
    } catch (error) {
      emit(ShiftsFailure(_messageFor(error)));
    }
  }

  Future<void> openShift({
    required num startingCash,
    required String pin,
  }) async {
    final currentState = state;
    if (currentState is! ShiftsNeedsOpening) return;
    if (startingCash > currentState.cashAvailability.availableCash) {
      emit(
        ShiftsNeedsOpening(
          currentState.cashAvailability,
          errorMessage: 'Modal melebihi kas yang tersedia. Perbarui data kas atau masukkan nominal lebih kecil.',
        ),
      );
      return;
    }

    emit(ShiftsOpening(currentState.cashAvailability));
    try {
      await _repository.openShift(startingCash: startingCash, pin: pin);
      final shift = await _repository.getActive();
      if (shift == null) {
        emit(
          ShiftsFailure(
            'Permintaan buka shift berhasil, tetapi shift aktif belum ditemukan. Muat ulang untuk memeriksa.',
          ),
        );
        return;
      }
      emit(ShiftsActive(shift));
    } catch (error) {
      emit(
        ShiftsNeedsOpening(
          currentState.cashAvailability,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> closeShift({
    required num actualCash,
    String? pin,
    String? notes,
  }) async {
    final currentState = state;
    if (currentState is! ShiftsActive) return;

    emit(ShiftsClosing(currentState.shift));
    try {
      final closedShift = await _repository.closeShift(
        shiftId: currentState.shift.id,
        actualCash: actualCash,
        pin: pin,
        notes: notes,
      );
      emit(ShiftsClosed(closedShift));
    } catch (error) {
      emit(ShiftsActive(currentState.shift, errorMessage: _messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
