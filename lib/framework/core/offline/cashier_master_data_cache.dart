import 'dart:convert';

import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/cached_records_dao.dart';

class CashierMasterDataCache {
  CashierMasterDataCache(this._dao, [this._userId, this._outletId])
    : _connectivityState = _CashierCacheConnectivityState();

  const CashierMasterDataCache.disabled()
    : _dao = null,
      _userId = null,
      _outletId = null,
      _connectivityState = null;

  final CachedRecordsDao? _dao;
  final String? _userId;
  final String? _outletId;
  final _CashierCacheConnectivityState? _connectivityState;

  String? get userId => _userId;
  String? get outletId => _outletId;
  bool get isOfflineKnown => _connectivityState?.isOffline ?? false;

  void markOffline() {
    final state = _connectivityState;
    if (state != null) state.isOffline = true;
  }

  void markOnline() {
    final state = _connectivityState;
    if (state != null) state.isOffline = false;
  }

  CashierMasterDataCache? forRole({
    required String role,
    required String userId,
    required String? outletId,
  }) {
    final dao = _dao;
    if (dao == null ||
        role != 'Kasir' ||
        userId.trim().isEmpty ||
        outletId == null ||
        outletId.trim().isEmpty) {
      return null;
    }
    final scopedCache = CashierMasterDataCache._(
      dao,
      userId,
      outletId,
      _connectivityState ?? _CashierCacheConnectivityState(),
    );
    return scopedCache;
  }

  bool get isScoped => _userId != null && _outletId != null;

  Future<void> saveCashierProfile({
    required String userId,
    required String role,
    required Object? payload,
  }) async {
    if (role != 'Kasir' || userId.trim().isEmpty) {
      throw ArgumentError('Snapshot sesi hanya dapat disimpan untuk Kasir.');
    }
    if (payload is! Map<String, dynamic> ||
        payload['id'] != userId ||
        payload['role'] != role) {
      throw ArgumentError('Profil cache tidak sesuai dengan pemilik sesi.');
    }
    final dao = _requireDao();
    await dao.saveCache(
      cacheType: 'cashier_session_profile',
      cacheKey: userId,
      payload: payload,
    );
  }

  Future<Object?> readCashierProfile(String userId) async {
    if (userId.trim().isEmpty) return null;
    final record = await _requireDao().getCache(
      'cashier_session_profile',
      userId,
    );
    if (record == null) return null;
    final payload = jsonDecode(record.payloadJson);
    if (payload is! Map<String, dynamic> ||
        payload['id'] != userId ||
        payload['role'] != 'Kasir') {
      return null;
    }
    return payload;
  }

  Future<void> saveCashierShiftSnapshot({
    required String userId,
    required String outletId,
    required String status,
    required DateTime verifiedAt,
    required Object? shift,
  }) async {
    if (userId.trim().isEmpty || outletId.trim().isEmpty) {
      throw ArgumentError('Snapshot shift harus memiliki akun dan outlet.');
    }
    if (shift is! Map<String, dynamic> || shift['status'] != status) {
      throw ArgumentError('Snapshot shift tidak cocok dengan status terakhir.');
    }
    await _requireDao().saveCache(
      cacheType: 'cashier_session_shift',
      cacheKey: userId,
      payload: {
        'user_id': userId,
        'outlet_id': outletId,
        'status': status,
        'verified_at': verifiedAt.toIso8601String(),
        'shift': shift,
      },
      updatedAt: verifiedAt,
    );
  }

  Future<Map<String, dynamic>?> readCashierShiftSnapshot(String userId) async {
    if (userId.trim().isEmpty) return null;
    final record = await _requireDao().getCache(
      'cashier_session_shift',
      userId,
    );
    if (record == null) return null;
    final payload = jsonDecode(record.payloadJson);
    if (payload is! Map<String, dynamic> ||
        payload['user_id'] != userId ||
        payload['outlet_id'] is! String ||
        (payload['outlet_id'] as String).trim().isEmpty ||
        payload['status'] is! String ||
        payload['verified_at'] is! String ||
        payload['shift'] is! Map<String, dynamic>) {
      return null;
    }
    return payload;
  }

  Future<void> deleteCashierShiftSnapshot(String userId) async {
    if (userId.trim().isEmpty) return;
    await _requireDao().deleteCache('cashier_session_shift', userId);
  }

  Future<void> save({
    required String cacheType,
    required String dataKey,
    required Object? payload,
  }) async {
    final userId = _userId;
    final outletId = _outletId;
    final dao = _dao;
    if (dao == null || userId == null || outletId == null) {
      throw StateError('Cache master data harus dibatasi ke akun dan outlet.');
    }

    await dao.saveCache(
      cacheType: cacheType,
      cacheKey: jsonEncode([userId, outletId, dataKey]),
      payload: payload,
    );
  }

  Future<Object?> read({
    required String cacheType,
    required String dataKey,
  }) async {
    final userId = _userId;
    final outletId = _outletId;
    final dao = _dao;
    if (dao == null || userId == null || outletId == null) return null;

    final record = await dao.getCache(
      cacheType,
      jsonEncode([userId, outletId, dataKey]),
    );
    return record == null ? null : jsonDecode(record.payloadJson);
  }

  Future<CachedRecord?> readRecord({
    required String cacheType,
    required String dataKey,
  }) async {
    final userId = _userId;
    final outletId = _outletId;
    final dao = _dao;
    if (dao == null || userId == null || outletId == null) return null;
    return dao.getCache(
      cacheType,
      jsonEncode([userId, outletId, dataKey]),
    );
  }

  CashierMasterDataCache._(
    this._dao,
    this._userId,
    this._outletId,
    this._connectivityState,
  );

  CachedRecordsDao _requireDao() {
    final dao = _dao;
    if (dao == null) {
      throw StateError('Database cache lokal tidak tersedia.');
    }
    return dao;
  }
}

class _CashierCacheConnectivityState {
  bool isOffline = false;
}
