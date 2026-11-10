import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/json_payload.dart';

enum OfflineTransactionStatus {
  pendingSync('pending_sync'),
  syncing('syncing'),
  synced('synced'),
  failed('failed'),
  needsReconciliation('needs_reconciliation');

  const OfflineTransactionStatus(this.databaseValue);

  final String databaseValue;
}

class OfflineTransactionsDao extends DatabaseAccessor<AppDatabase> {
  OfflineTransactionsDao(super.database) : _database = database;

  static const Uuid _uuid = Uuid();
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
      return (select(
        _database.offlineTransactions,
      )..where((record) => record.localId.equals(transactionLocalId))).getSingle();
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

  Future<List<OfflineTransaction>> getUnresolvedSales({
    required String ownerUserId,
    required String outletId,
  }) {
    const unresolvedStatuses = [
      'pending_sync',
      'syncing',
      'failed',
      'needs_reconciliation',
    ];
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

  Future<bool> updateSyncStatus({
    required String localId,
    required OfflineTransactionStatus status,
    String? remoteTransactionId,
    String? lastError,
    DateTime? updatedAt,
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
            syncedAt: Value(
              status == OfflineTransactionStatus.synced ? now : null,
            ),
            attemptCount: status == OfflineTransactionStatus.syncing
                ? Value(current.attemptCount + 1)
                : const Value.absent(),
            lastError: status == OfflineTransactionStatus.failed
                ? Value(lastError)
                : status == OfflineTransactionStatus.synced
                ? const Value(null)
                : const Value.absent(),
          ),
        );
    return updatedCount > 0;
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
