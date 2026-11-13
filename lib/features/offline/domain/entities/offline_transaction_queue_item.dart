class OfflineTransactionQueueItem {
  const OfflineTransactionQueueItem({
    required this.localId,
    required this.ownerUserId,
    required this.outletId,
    required this.shiftId,
    required this.transactionType,
    required this.payloadJson,
    required this.receiptSnapshotJson,
    required this.status,
    required this.createdAtLocal,
    this.remoteTransactionId,
    this.lastError,
  });

  final String localId;
  final String ownerUserId;
  final String outletId;
  final String shiftId;
  final String transactionType;
  final String payloadJson;
  final String receiptSnapshotJson;
  final String status;
  final DateTime createdAtLocal;
  final String? remoteTransactionId;
  final String? lastError;
}

class OfflineTransactionResolutionAudit {
  const OfflineTransactionResolutionAudit({
    required this.resolutionType,
    required this.resolvingAdminUserId,
    required this.resolvingAdminRole,
    required this.reason,
    required this.resolvedAt,
    this.notes,
  });

  final String resolutionType;
  final String resolvingAdminUserId;
  final String resolvingAdminRole;
  final String reason;
  final DateTime resolvedAt;
  final String? notes;
}

const offlineTransactionUnresolvedStatuses = [
  'pending_sync',
  'syncing',
  'failed',
  'needs_reconciliation',
];
