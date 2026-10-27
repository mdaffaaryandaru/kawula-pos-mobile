import '../entities/active_shift.dart';
import '../entities/admin_shift_detail.dart';

abstract interface class AdminShiftsRepository {
  Future<List<ActiveShift>> getShifts({String? status});

  Future<AdminShiftDetail> getShiftDetail(String shiftId);

  Future<ActiveShift> forceCloseShift({
    required String shiftId,
    required num actualCash,
    required String notes,
  });
}
