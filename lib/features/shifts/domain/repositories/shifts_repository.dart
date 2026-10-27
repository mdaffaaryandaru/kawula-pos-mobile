import '../entities/active_shift.dart';

abstract interface class ShiftsRepository {
  Future<ActiveShift?> getActive();

  Future<CashAvailability> getCashAvailability();

  Future<void> openShift({required num startingCash, required String pin});

  Future<ActiveShift> closeShift({
    required String shiftId,
    required num actualCash,
    String? pin,
    String? notes,
  });
}
