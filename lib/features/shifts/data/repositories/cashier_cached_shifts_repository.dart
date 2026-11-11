import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:kawula_pos/features/shifts/data/models/active_shift_model.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/entities/admin_shift_detail.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/platform_network_exception.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';

class CashierCachedShiftsRepository implements ShiftsRepository {
  const CashierCachedShiftsRepository(
    this._delegate,
    this._cache, {
    required this.ownerUserId,
    this.role = 'Kasir',
  });

  final ShiftsRepository _delegate;
  final CashierMasterDataCache _cache;
  final String ownerUserId;
  final String role;

  @override
  Future<ActiveShift?> getActive() async {
    final ActiveShift? shift;
    try {
      shift = await _delegate.getActive();
    } on http.ClientException {
      _cache.markOffline();
      return _readCachedActiveShift();
    } on TimeoutException {
      _cache.markOffline();
      return _readCachedActiveShift();
    } on ApiException catch (error) {
      if (error.statusCode != null && error.statusCode! < 500) {
        _cache.markOnline();
      } else {
        _cache.markOffline();
      }
      rethrow;
    } on Exception catch (error) {
      if (!isPlatformNetworkException(error)) rethrow;
      _cache.markOffline();
      return _readCachedActiveShift();
    }

    _cache.markOnline();
    if (shift == null) {
      await _cache.deleteCashierShiftSnapshot(ownerUserId, role: role);
      return null;
    }

    final outletId = shift.outletId;
    if (outletId == null || outletId.trim().isEmpty) {
      await _cache.deleteCashierShiftSnapshot(ownerUserId, role: role);
      return shift;
    }

    await _cache.saveCashierShiftSnapshot(
      userId: ownerUserId,
      outletId: outletId,
      status: shift.status,
      verifiedAt: DateTime.now(),
      role: role,
      shift: ActiveShiftModel.fromEntity(shift).toJson(),
    );
    return shift;
  }

  Future<ActiveShift?> _readCachedActiveShift() async {
    final snapshot = await _cache.readCashierShiftSnapshot(
      ownerUserId,
      role: role,
    );
    if (snapshot == null ||
        snapshot['status'].toString().toLowerCase() != 'open') {
      return null;
    }

    final shiftJson = snapshot['shift'];
    if (shiftJson is! Map<String, dynamic>) return null;
    final shift = ActiveShiftModel.fromJson(shiftJson, isOfflineSnapshot: true);
    if (shift.status.toLowerCase() != 'open' ||
        shift.outletId != snapshot['outlet_id']) {
      return null;
    }
    DateTime.parse(snapshot['verified_at'] as String);
    return shift;
  }

  @override
  Future<CashAvailability> getCashAvailability() =>
      _delegate.getCashAvailability();

  @override
  Future<void> openShift({required num startingCash, required String pin}) =>
      _delegate.openShift(startingCash: startingCash, pin: pin);

  @override
  Future<ActiveShift> closeShift({
    required String shiftId,
    required num actualCash,
    String? pin,
    String? notes,
  }) async {
    final closedShift = await _delegate.closeShift(
      shiftId: shiftId,
      actualCash: actualCash,
      pin: pin,
      notes: notes,
    );
    await _cache.deleteCashierShiftSnapshot(ownerUserId, role: role);
    return closedShift;
  }

  @override
  Future<List<ActiveShift>> getShifts({String? status}) =>
      _delegate.getShifts(status: status);

  @override
  Future<AdminShiftDetail> getShiftDetail(String shiftId) =>
      _delegate.getShiftDetail(shiftId);

  @override
  Future<ActiveShift> forceCloseShift({
    required String shiftId,
    required num actualCash,
    required String notes,
  }) => _delegate.forceCloseShift(
    shiftId: shiftId,
    actualCash: actualCash,
    notes: notes,
  );
}
