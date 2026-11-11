import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/cached_records_dao.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

enum OfflineNetworkStatus { online, offline, checking }

class OfflineMasterDataCache {
  OfflineMasterDataCache(this._dao, [this._userId, this._outletId, this._role])
    : _connectivityState = _OfflineCacheConnectivityState();

  const OfflineMasterDataCache.disabled()
    : _dao = null,
      _userId = null,
      _outletId = null,
      _role = null,
      _connectivityState = null;

  final CachedRecordsDao? _dao;
  final String? _userId;
  final String? _outletId;
  final String? _role;
  final _OfflineCacheConnectivityState? _connectivityState;

  String? get userId => _userId;
  String? get outletId => _outletId;
  String? get role => _role;
  ValueListenable<OfflineNetworkStatus>? get networkStatusListenable =>
      _connectivityState?.status;
  OfflineNetworkStatus get networkStatus =>
      _connectivityState?.status.value ?? OfflineNetworkStatus.online;
  bool get isOfflineKnown => networkStatus == OfflineNetworkStatus.offline;
  bool get shouldUseOfflineData => networkStatus != OfflineNetworkStatus.online;

  void markOffline() {
    final state = _connectivityState;
    state?.status.value = OfflineNetworkStatus.offline;
  }

  void markChecking() {
    final state = _connectivityState;
    state?.status.value = OfflineNetworkStatus.checking;
  }

  void markOnline() {
    final state = _connectivityState;
    state?.status.value = OfflineNetworkStatus.online;
  }

  OfflineMasterDataCache? forRole({
    required String role,
    required String userId,
    required String? outletId,
  }) {
    final dao = _dao;
    if (dao == null ||
        !canUseOfflineSales(role) ||
        userId.trim().isEmpty ||
        outletId == null ||
        outletId.trim().isEmpty) {
      return null;
    }
    final scopedCache = OfflineMasterDataCache._(
      dao,
      userId,
      outletId,
      role,
      _connectivityState!,
    );
    return scopedCache;
  }

  bool get isScoped => _userId != null && _outletId != null && _role != null;

  Future<void> saveOfflineSalesProfile({
    required String userId,
    required String role,
    required Object? payload,
  }) async {
    if (!canUseOfflineSales(role) || userId.trim().isEmpty) {
      throw ArgumentError(
        'Snapshot sesi tidak memiliki role Offline Sales yang valid.',
      );
    }
    if (payload is! Map<String, dynamic> ||
        payload['id'] != userId ||
        payload['role'] != role) {
      throw ArgumentError('Profil cache tidak sesuai dengan pemilik sesi.');
    }
    final dao = _requireDao();
    final otherRole = role == 'Admin' ? 'Kasir' : 'Admin';
    await dao.deleteCache(
      'offline_sales_session_profile',
      jsonEncode([userId, otherRole]),
    );
    await dao.saveCache(
      cacheType: 'offline_sales_session_profile',
      cacheKey: jsonEncode([userId, role]),
      payload: payload,
    );
  }

  Future<Object?> readOfflineSalesProfile(String userId, {String? role}) async {
    if (userId.trim().isEmpty) return null;
    final cacheRole = role ?? _role;
    if (cacheRole != null && !canUseOfflineSales(cacheRole)) return null;
    final dao = _requireDao();
    final record = cacheRole == null
        ? await dao.getCache(
                'offline_sales_session_profile',
                jsonEncode([userId, 'Admin']),
              ) ??
              await dao.getCache(
                'offline_sales_session_profile',
                jsonEncode([userId, 'Kasir']),
              )
        : await dao.getCache(
            'offline_sales_session_profile',
            jsonEncode([userId, cacheRole]),
          );
    final legacyRecord =
        record ??
        (cacheRole == null || cacheRole == 'Kasir'
            // TODO: Keep this legacy cache key until the minimum supported app version is known.
            ? await dao.getCache('cashier_session_profile', userId)
            : null);
    if (legacyRecord == null) return null;
    final payload = jsonDecode(legacyRecord.payloadJson);
    if (payload is! Map<String, dynamic> ||
        payload['id'] != userId ||
        payload['role'] is! String ||
        !canUseOfflineSales(payload['role'] as String) ||
        (cacheRole != null && payload['role'] != cacheRole)) {
      return null;
    }
    return payload;
  }

  Future<void> saveOfflineSalesShiftSnapshot({
    required String userId,
    required String outletId,
    required String status,
    required DateTime verifiedAt,
    String? role,
    required Object? shift,
  }) async {
    final cacheRole = role ?? _role ?? 'Kasir';
    if (!canUseOfflineSales(cacheRole) ||
        userId.trim().isEmpty ||
        outletId.trim().isEmpty) {
      throw ArgumentError('Snapshot shift harus memiliki akun dan outlet.');
    }
    if (shift is! Map<String, dynamic> || shift['status'] != status) {
      throw ArgumentError('Snapshot shift tidak cocok dengan status terakhir.');
    }
    await _requireDao().saveCache(
      cacheType: 'cashier_session_shift',
      cacheKey: jsonEncode([userId, cacheRole]),
      payload: {
        'user_id': userId,
        'outlet_id': outletId,
        'role': cacheRole,
        'status': status,
        'verified_at': verifiedAt.toIso8601String(),
        'shift': shift,
      },
      updatedAt: verifiedAt,
    );
  }

  Future<Map<String, dynamic>?> readOfflineSalesShiftSnapshot(
    String userId, {
    String? role,
  }) async {
    if (userId.trim().isEmpty) return null;
    final cacheRole = role ?? _role;
    if (cacheRole != null && !canUseOfflineSales(cacheRole)) return null;
    final dao = _requireDao();
    final record = cacheRole == null
        ? await dao.getCache(
                'cashier_session_shift',
                jsonEncode([userId, 'Admin']),
              ) ??
              await dao.getCache(
                'cashier_session_shift',
                jsonEncode([userId, 'Kasir']),
              ) ??
              await dao.getCache('cashier_session_shift', userId)
        : await dao.getCache(
                'cashier_session_shift',
                jsonEncode([userId, cacheRole]),
              ) ??
              (cacheRole == 'Kasir'
                  ? await dao.getCache('cashier_session_shift', userId)
                  : null);
    if (record == null) return null;
    final payload = jsonDecode(record.payloadJson);
    if (payload is! Map<String, dynamic> ||
        payload['user_id'] != userId ||
        (cacheRole != null &&
            payload['role'] != cacheRole &&
            !(cacheRole == 'Kasir' && payload['role'] == null)) ||
        payload['outlet_id'] is! String ||
        (payload['outlet_id'] as String).trim().isEmpty ||
        payload['status'] is! String ||
        payload['verified_at'] is! String ||
        payload['shift'] is! Map<String, dynamic>) {
      return null;
    }
    return payload;
  }

  Future<void> deleteOfflineSalesShiftSnapshot(
    String userId, {
    String? role,
  }) async {
    if (userId.trim().isEmpty) return;
    final dao = _requireDao();
    final cacheRole = role ?? _role;
    if (cacheRole != null) {
      await dao.deleteCache(
        'cashier_session_shift',
        jsonEncode([userId, cacheRole]),
      );
    }
    if (cacheRole == null || cacheRole == 'Kasir') {
      await dao.deleteCache('cashier_session_shift', userId);
    }
  }

  Future<void> save({
    required String cacheType,
    required String dataKey,
    required Object? payload,
  }) async {
    final userId = _userId;
    final outletId = _outletId;
    final role = _role;
    final dao = _dao;
    if (dao == null || userId == null || outletId == null || role == null) {
      throw StateError('Cache master data harus dibatasi ke akun dan outlet.');
    }

    await dao.saveCache(
      cacheType: cacheType,
      cacheKey: jsonEncode([userId, role, outletId, dataKey]),
      payload: payload,
    );
  }

  Future<Object?> read({
    required String cacheType,
    required String dataKey,
  }) async {
    final userId = _userId;
    final outletId = _outletId;
    final role = _role;
    final dao = _dao;
    if (dao == null || userId == null || outletId == null || role == null) {
      return null;
    }

    var record = await dao.getCache(
      cacheType,
      jsonEncode([userId, role, outletId, dataKey]),
    );
    if (record == null && role == 'Kasir') {
      record = await dao.getCache(
        cacheType,
        jsonEncode([userId, outletId, dataKey]),
      );
    }
    return record == null ? null : jsonDecode(record.payloadJson);
  }

  Future<CachedRecord?> readRecord({
    required String cacheType,
    required String dataKey,
  }) async {
    final userId = _userId;
    final outletId = _outletId;
    final role = _role;
    final dao = _dao;
    if (dao == null || userId == null || outletId == null || role == null) {
      return null;
    }
    var record = await dao.getCache(
      cacheType,
      jsonEncode([userId, role, outletId, dataKey]),
    );
    if (record == null && role == 'Kasir') {
      record = await dao.getCache(
        cacheType,
        jsonEncode([userId, outletId, dataKey]),
      );
    }
    return record;
  }

  OfflineMasterDataCache._(
    this._dao,
    this._userId,
    this._outletId,
    this._role,
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

class _OfflineCacheConnectivityState {
  final ValueNotifier<OfflineNetworkStatus> status = ValueNotifier(
    OfflineNetworkStatus.online,
  );
}
