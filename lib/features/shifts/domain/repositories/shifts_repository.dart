import '../entities/active_shift.dart';
import 'admin_shifts_repository.dart';

abstract interface class ShiftsRepository implements AdminShiftsRepository {
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
