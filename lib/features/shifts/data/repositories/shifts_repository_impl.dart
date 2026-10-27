import '../../domain/entities/active_shift.dart';
import '../../domain/repositories/shifts_repository.dart';
import '../datasources/shifts_remote_data_source.dart';

class ShiftsRepositoryImpl implements ShiftsRepository {
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
}
