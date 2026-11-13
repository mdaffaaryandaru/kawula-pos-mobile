import 'package:kawula_pos/features/offline/domain/entities/offline_transaction_queue_item.dart';

abstract interface class OfflineTransactionQueueRepository {
  Stream<List<OfflineTransactionQueueItem>> watchTransactionsByOutletLatest(
    String outletId,
  );

  Stream<List<OfflineTransactionQueueItem>> watchTransactionsByOwnerLatest(
    String ownerUserId,
  );

  Future<OfflineTransactionQueueItem?> getTransactionByLocalId(String localId);

  Future<int> getUnresolvedTransactionCount({
    required String ownerUserId,
    required String outletId,
    required String shiftId,
  });

  Future<List<OfflineTransactionResolutionAudit>> getResolutionAudit(
    String localId,
  );

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
  });
}
