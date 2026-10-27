import '../../domain/entities/active_shift.dart';
import '../../domain/entities/admin_shift_detail.dart';
import '../../domain/repositories/admin_shifts_repository.dart';
import '../../domain/repositories/shifts_repository.dart';
import '../datasources/shifts_remote_data_source.dart';

class ShiftsRepositoryImpl
    implements ShiftsRepository, AdminShiftsRepository {
  const ShiftsRepositoryImpl(this._remoteDataSource);

  final ShiftsRemoteDataSource _remoteDataSource;

  @override
  Future<ActiveShift?> getActive() => _remoteDataSource.getActive();

  @override
  Future<CashAvailability> getCashAvailability() =>
      _remoteDataSource.getCashAvailability();

  @override
  Future<void> openShift({required num startingCash, required String pin}) {
    return _remoteDataSource.openShift(startingCash: startingCash, pin: pin);
  }

  @override
  Future<ActiveShift> closeShift({
    required String shiftId,
    required num actualCash,
    String? pin,
    String? notes,
  }) {
    return _remoteDataSource.closeShift(
      shiftId: shiftId,
      actualCash: actualCash,
      pin: pin,
      notes: notes,
    );
  }

  @override
  Future<List<ActiveShift>> getShifts({String? status}) =>
      _remoteDataSource.getShifts(status: status);

  @override
  Future<AdminShiftDetail> getShiftDetail(String shiftId) =>
      _remoteDataSource.getShiftDetail(shiftId);

  @override
  Future<ActiveShift> forceCloseShift({
    required String shiftId,
    required num actualCash,
    required String notes,
  }) => _remoteDataSource.forceCloseShift(
    shiftId: shiftId,
    actualCash: actualCash,
    notes: notes,
  );
}
