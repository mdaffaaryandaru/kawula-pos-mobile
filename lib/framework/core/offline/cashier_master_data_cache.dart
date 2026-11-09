import 'dart:convert';

import 'package:kawula_pos/framework/core/offline/database/daos/cached_records_dao.dart';

class CashierMasterDataCache {
  const CashierMasterDataCache(this._dao, [this._userId, this._outletId]);

  const CashierMasterDataCache.disabled()
    : _dao = null,
      _userId = null,
      _outletId = null;

  final CachedRecordsDao? _dao;
  final String? _userId;
  final String? _outletId;

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
    return CashierMasterDataCache(dao, userId, outletId);
  }

  bool get isScoped => _userId != null && _outletId != null;

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
}
