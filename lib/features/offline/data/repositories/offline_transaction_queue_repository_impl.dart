import 'package:kawula_pos/features/offline/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/offline/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/features/offline/data/database/app_database.dart';
import 'package:kawula_pos/features/offline/data/database/daos/offline_transactions_dao.dart';

class OfflineTransactionQueueRepositoryImpl
    implements OfflineTransactionQueueRepository {
  const OfflineTransactionQueueRepositoryImpl(this._dao);

  final OfflineTransactionsDao _dao;

  @override
  Stream<List<OfflineTransactionQueueItem>> watchTransactionsByOutletLatest(
    String outletId,
  ) => _dao
      .watchTransactionsByOutletLatest(outletId)
      .map((transactions) => transactions.map(_toQueueItem).toList());

  @override
  Stream<List<OfflineTransactionQueueItem>> watchTransactionsByOwnerLatest(
    String ownerUserId,
  ) => _dao
      .watchTransactionsByOwnerLatest(ownerUserId)
      .map(
        (transactions) =>
            transactions.map(_toQueueItem).toList(growable: false),
      );

  @override
  Future<OfflineTransactionQueueItem?> getTransactionByLocalId(
    String localId,
  ) async {
    final transaction = await _dao.getTransactionByLocalId(localId);
    return transaction == null ? null : _toQueueItem(transaction);
  }

  @override
  Future<int> getUnresolvedTransactionCount({
    required String ownerUserId,
    required String outletId,
    required String shiftId,
  }) async => (await _dao.getUnresolvedTransactions(
    ownerUserId: ownerUserId,
    outletId: outletId,
    shiftId: shiftId,
  )).length;

  @override
  Future<List<OfflineTransactionResolutionAudit>> getResolutionAudit(
    String localId,
  ) async {
    final audit = await _dao.getResolutionAudit(localId);
    return audit
        .map(
          (entry) => OfflineTransactionResolutionAudit(
            resolutionType: entry.resolutionType,
            resolvingAdminUserId: entry.resolvingAdminUserId,
            resolvingAdminRole: entry.resolvingAdminRole,
            reason: entry.reason,
            resolvedAt: entry.resolvedAt,
            notes: entry.notes,
          ),
        )
        .toList(growable: false);
  }

  @override
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
  }) => _dao.resolveManually(
    localId: localId,
    outletId: outletId,
    adminUserId: adminUserId,
    adminRole: adminRole,
    resolutionType: resolutionType,
    reason: reason,
    resolvedAt: resolvedAt,
    remoteTransactionId: remoteTransactionId,
    notes: notes,
  );

  OfflineTransactionQueueItem _toQueueItem(OfflineTransaction transaction) =>
      OfflineTransactionQueueItem(
        localId: transaction.localId,
        ownerUserId: transaction.ownerUserId,
        outletId: transaction.outletId,
        shiftId: transaction.shiftId,
        transactionType: transaction.transactionType,
        payloadJson: transaction.payloadJson,
        receiptSnapshotJson: transaction.receiptSnapshotJson,
        status: transaction.status,
        createdAtLocal: transaction.createdAtLocal,
        remoteTransactionId: transaction.remoteTransactionId,
        lastError: transaction.lastError,
      );
}
