import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/json_payload.dart';

enum OfflineTransactionStatus {
  pendingSync('pending_sync'),
  syncing('syncing'),
  synced('synced'),
  failed('failed'),
  needsReconciliation('needs_reconciliation'),
  resolvedManually('resolved_manually');

  const OfflineTransactionStatus(this.databaseValue);

  final String databaseValue;
}

class OfflineTransactionsDao extends DatabaseAccessor<AppDatabase> {
  OfflineTransactionsDao(super.database) : _database = database;

  static const Uuid _uuid = Uuid();
  static const unresolvedStatuses = [
    'pending_sync',
    'syncing',
    'failed',
    'needs_reconciliation',
  ];
  final AppDatabase _database;

  Future<OfflineTransaction> saveOfflineTransaction({
    required String ownerUserId,
    required String outletId,
    required String shiftId,
    required String transactionType,
    required Object? payload,
    required Object? receiptSnapshot,
    DateTime? createdAtLocal,
    String? localId,
    String? syncMarker,
    String? lastError,
    OfflineTransactionStatus status = OfflineTransactionStatus.pendingSync,
  }) async {
    _validateRequiredValue(ownerUserId, 'ownerUserId');
    _validateRequiredValue(outletId, 'outletId');
    _validateRequiredValue(shiftId, 'shiftId');
    _validateRequiredValue(transactionType, 'transactionType');

    final transactionLocalId = localId ?? 'OFF-${_uuid.v4()}';
    final transactionSyncMarker = syncMarker ?? 'OFFLINE_SYNC:${_uuid.v4()}';
    _validateRequiredValue(transactionLocalId, 'localId');
    _validateRequiredValue(transactionSyncMarker, 'syncMarker');
    if (!transactionLocalId.startsWith('OFF-')) {
      throw ArgumentError.value(
        transactionLocalId,
        'localId',
        'ID transaksi lokal harus diawali OFF-.',
      );
    }
    final payloadJson = encodeJsonWithoutCredentials(payload);
    final receiptSnapshotJson = encodeJsonWithoutCredentials(receiptSnapshot);
    final createdAt = createdAtLocal ?? DateTime.now();

    return transaction(() async {
      await into(_database.offlineTransactions).insert(
        OfflineTransactionsCompanion.insert(
          localId: transactionLocalId,
          ownerUserId: ownerUserId,
          outletId: outletId,
          shiftId: shiftId,
          transactionType: transactionType,
          syncMarker: transactionSyncMarker,
          payloadJson: payloadJson,
          receiptSnapshotJson: receiptSnapshotJson,
          createdAtLocal: createdAt,
          updatedAt: createdAt,
          status: Value(status.databaseValue),
          lastError: Value(lastError),
        ),
      );
      return (select(_database.offlineTransactions)
            ..where((record) => record.localId.equals(transactionLocalId)))
          .getSingle();
    });
  }

  Future<OfflineTransaction?> getTransactionByLocalId(String localId) {
    return (select(
      _database.offlineTransactions,
    )..where((record) => record.localId.equals(localId))).getSingleOrNull();
  }

  Future<List<OfflineTransaction>> getTransactionsByOwner(String ownerUserId) {
    return (select(_database.offlineTransactions)
          ..where((record) => record.ownerUserId.equals(ownerUserId))
          ..orderBy([
            (record) => OrderingTerm.asc(record.createdAtLocal),
            (record) => OrderingTerm.asc(record.localId),
          ]))
        .get();
  }

  Stream<List<OfflineTransaction>> watchTransactionsByOutletLatest(
    String outletId,
  ) {
    return (select(_database.offlineTransactions)
          ..where((record) => record.outletId.equals(outletId))
          ..orderBy([
            (record) => OrderingTerm.desc(record.createdAtLocal),
            (record) => OrderingTerm.desc(record.localId),
          ]))
        .watch();
  }

  Future<List<OfflineTransaction>> getTransactionsByOutlet({
    required String outletId,
    String? ownerUserId,
  }) {
    return (select(_database.offlineTransactions)
          ..where((record) {
            final outletCondition = record.outletId.equals(outletId);
            return ownerUserId == null
                ? outletCondition
                : outletCondition & record.ownerUserId.equals(ownerUserId);
          })
          ..orderBy([
            (record) => OrderingTerm.desc(record.createdAtLocal),
            (record) => OrderingTerm.desc(record.localId),
          ]))
        .get();
  }

  Future<List<OfflineTransactionResolution>> getResolutionAudit(
    String localId,
  ) {
    return (select(_database.offlineTransactionResolutions)
          ..where((entry) => entry.localId.equals(localId))
          ..orderBy([(entry) => OrderingTerm.asc(entry.resolvedAt)]))
        .get();
  }

  Future<bool> resolveManually({
    required String localId,
    required String outletId,
    required String adminUserId,
    required String adminRole,
    required String resolutionType,
    required String reason,
    required DateTime resolvedAt,
    String? remoteTransactionId,
    String? notes,
  }) async {
    _validateRequiredValue(adminUserId, 'adminUserId');
    _validateRequiredValue(outletId, 'outletId');
    _validateRequiredValue(reason, 'reason');
    if (adminRole != 'Admin') {
      throw ArgumentError.value(adminRole, 'adminRole', 'Role Admin wajib.');
    }
    if (resolutionType == 'matched_existing_remote' &&
        (remoteTransactionId == null || remoteTransactionId.trim().isEmpty)) {
      throw ArgumentError.value(
        remoteTransactionId,
        'remoteTransactionId',
        'ID transaksi server wajib untuk pencocokan.',
      );
    }
    if (resolutionType == 'handled_outside_server' &&
        remoteTransactionId != null) {
      throw ArgumentError.value(
        remoteTransactionId,
        'remoteTransactionId',
        'Penyelesaian di luar server tidak boleh memiliki ID server.',
      );
    }
    if (!const {
      'matched_existing_remote',
      'handled_outside_server',
    }.contains(resolutionType)) {
      throw ArgumentError.value(
        resolutionType,
        'resolutionType',
        'Jenis penyelesaian tidak dikenal.',
      );
    }

    return transaction(() async {
      final current =
          await (select(_database.offlineTransactions)..where(
                (record) =>
                    record.localId.equals(localId) &
                    record.outletId.equals(outletId) &
                    record.status.isIn([
                      OfflineTransactionStatus.failed.databaseValue,
                      OfflineTransactionStatus
                          .needsReconciliation
                          .databaseValue,
                    ]),
              ))
              .getSingleOrNull();
      if (current == null) return false;
      if (resolutionType == 'handled_outside_server' &&
          current.status != OfflineTransactionStatus.failed.databaseValue) {
        throw StateError(
          'Transaksi dengan status belum pasti tidak dapat ditangani di luar server.',
        );
      }

      final updatedCount =
          await (update(_database.offlineTransactions)..where(
                (record) =>
                    record.localId.equals(localId) &
                    record.outletId.equals(outletId) &
                    record.status.equals(current.status),
              ))
              .write(
                OfflineTransactionsCompanion(
                  status: Value(
                    OfflineTransactionStatus.resolvedManually.databaseValue,
                  ),
                  remoteTransactionId:
                      resolutionType == 'matched_existing_remote'
                      ? Value(remoteTransactionId)
                      : const Value.absent(),
                  updatedAt: Value(resolvedAt),
                ),
              );
      if (updatedCount == 0) return false;

      await into(_database.offlineTransactionResolutions).insert(
        OfflineTransactionResolutionsCompanion.insert(
          localId: localId,
          outletId: outletId,
          previousStatus: current.status,
          resultingStatus:
              OfflineTransactionStatus.resolvedManually.databaseValue,
          resolutionType: resolutionType,
          remoteTransactionId: Value(remoteTransactionId),
          resolvingAdminUserId: adminUserId,
          resolvingAdminRole: adminRole,
          resolvedAt: resolvedAt,
          reason: reason.trim(),
          notes: Value(notes?.trim().isEmpty == true ? null : notes?.trim()),
        ),
      );
      return true;
    });
  }

  Stream<List<OfflineTransaction>> watchTransactionsByOwnerLatest(
    String ownerUserId,
  ) {
    return (select(_database.offlineTransactions)
          ..where((record) => record.ownerUserId.equals(ownerUserId))
          ..orderBy([
            (record) => OrderingTerm.desc(record.createdAtLocal),
            (record) => OrderingTerm.desc(record.localId),
          ]))
        .watch();
  }

  Future<List<OfflineTransaction>> getUnresolvedByOwnerAndOutlet({
    required String ownerUserId,
    required String outletId,
  }) {
    return (select(_database.offlineTransactions)
          ..where(
            (record) =>
                record.ownerUserId.equals(ownerUserId) &
                record.outletId.equals(outletId) &
                record.status.isIn(unresolvedStatuses),
          )
          ..orderBy([
            (record) => OrderingTerm.asc(record.createdAtLocal),
            (record) => OrderingTerm.asc(record.localId),
          ]))
        .get();
  }

  Future<List<OfflineTransaction>> getUnresolvedTransactions({
    required String ownerUserId,
    required String outletId,
    required String shiftId,
  }) {
    return (select(_database.offlineTransactions)
          ..where(
            (record) =>
                record.ownerUserId.equals(ownerUserId) &
                record.outletId.equals(outletId) &
                record.shiftId.equals(shiftId) &
                record.status.isIn(unresolvedStatuses),
          )
          ..orderBy([
            (record) => OrderingTerm.asc(record.createdAtLocal),
            (record) => OrderingTerm.asc(record.localId),
          ]))
        .get();
  }

  Future<List<OfflineTransaction>> getUnresolvedSales({
    required String ownerUserId,
    required String outletId,
  }) {
    return (select(_database.offlineTransactions)
          ..where(
            (record) =>
                record.ownerUserId.equals(ownerUserId) &
                record.outletId.equals(outletId) &
                record.transactionType.equals('sale') &
                record.status.isIn(unresolvedStatuses),
          )
          ..orderBy([
            (record) => OrderingTerm.asc(record.createdAtLocal),
            (record) => OrderingTerm.asc(record.localId),
          ]))
        .get();
  }

  Future<List<OfflineTransaction>> getTransactionsByStatus(
    OfflineTransactionStatus status, {
    String? ownerUserId,
  }) {
    final query = select(_database.offlineTransactions)
      ..where((record) {
        final statusCondition = record.status.equals(status.databaseValue);
        if (ownerUserId == null) {
          return statusCondition;
        }
        return statusCondition & record.ownerUserId.equals(ownerUserId);
      })
      ..orderBy([
        (record) => OrderingTerm.asc(record.createdAtLocal),
        (record) => OrderingTerm.asc(record.localId),
      ]);
    return query.get();
  }

  Future<List<OfflineTransaction>> getFifoQueue({
    required String ownerUserId,
    List<OfflineTransactionStatus> statuses = const [
      OfflineTransactionStatus.pendingSync,
      OfflineTransactionStatus.syncing,
      OfflineTransactionStatus.failed,
    ],
  }) {
    final statusValues = statuses
        .map((status) => status.databaseValue)
        .toList();
    final query = select(_database.offlineTransactions)
      ..where((record) {
        final ownerCondition = record.ownerUserId.equals(ownerUserId);
        if (statusValues.isEmpty) {
          return const Constant<bool>(false);
        }
        return ownerCondition & record.status.isIn(statusValues);
      })
      ..orderBy([
        (record) => OrderingTerm.asc(record.createdAtLocal),
        (record) => OrderingTerm.asc(record.localId),
      ]);
    return query.get();
  }

  Future<bool> updateTransactionStatus({
    required String localId,
    required OfflineTransactionStatus status,
    String? remoteTransactionId,
    String? lastError,
    DateTime? updatedAt,
    bool incrementAttemptCount = false,
  }) async {
    if (status == OfflineTransactionStatus.failed &&
        (lastError == null || lastError.trim().isEmpty)) {
      throw ArgumentError.value(
        lastError,
        'lastError',
        'Alasan kegagalan wajib diisi.',
      );
    }

    final current = await getTransactionByLocalId(localId);
    if (current == null) {
      return false;
    }

    final now = updatedAt ?? DateTime.now();
    final updatedCount =
        await (update(
          _database.offlineTransactions,
        )..where((record) => record.localId.equals(localId))).write(
          OfflineTransactionsCompanion(
            status: Value(status.databaseValue),
            remoteTransactionId: remoteTransactionId == null
                ? const Value.absent()
                : Value(remoteTransactionId),
            updatedAt: Value(now),
            syncedAt: status == OfflineTransactionStatus.synced
                ? Value(now)
                : status == OfflineTransactionStatus.pendingSync
                ? const Value(null)
                : Value(current.syncedAt),
            attemptCount:
                incrementAttemptCount ||
                    status == OfflineTransactionStatus.syncing
                ? Value(current.attemptCount + 1)
                : const Value.absent(),
            lastError: lastError == null
                ? status == OfflineTransactionStatus.synced
                      ? const Value(null)
                      : const Value.absent()
                : Value(lastError),
          ),
        );
    return updatedCount > 0;
  }

  Future<bool> updateSyncStatus({
    required String localId,
    required OfflineTransactionStatus status,
    String? remoteTransactionId,
    String? lastError,
    DateTime? updatedAt,
  }) async {
    return updateTransactionStatus(
      localId: localId,
      status: status,
      remoteTransactionId: remoteTransactionId,
      lastError: lastError,
      updatedAt: updatedAt,
      incrementAttemptCount: status == OfflineTransactionStatus.syncing,
    );
  }

  void _validateRequiredValue(String value, String argumentName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        argumentName,
        'Nilai tidak boleh kosong.',
      );
    }
  }
}
