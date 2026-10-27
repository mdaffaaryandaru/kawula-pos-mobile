import '../../domain/entities/active_shift.dart';

sealed class ShiftsState {
  const ShiftsState();
}

final class ShiftsLoading extends ShiftsState {
  const ShiftsLoading();
}

final class ShiftsNeedsOpening extends ShiftsState {
  const ShiftsNeedsOpening(this.cashAvailability, {this.errorMessage});

  final CashAvailability cashAvailability;
  final String? errorMessage;
}

final class ShiftsOpening extends ShiftsState {
  const ShiftsOpening(this.cashAvailability);

  final CashAvailability cashAvailability;
}

final class ShiftsActive extends ShiftsState {
  const ShiftsActive(this.shift, {this.errorMessage});

  final ActiveShift shift;
  final String? errorMessage;
}

final class ShiftsClosing extends ShiftsState {
  const ShiftsClosing(this.shift);

  final ActiveShift shift;
}

final class ShiftsClosed extends ShiftsState {
  const ShiftsClosed(this.shift);

  final ActiveShift shift;
}

final class ShiftsFailure extends ShiftsState {
  const ShiftsFailure(this.message);

  final String message;
}
