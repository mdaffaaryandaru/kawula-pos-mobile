class OfflineTransactionSyncSummary {
  const OfflineTransactionSyncSummary({
    required this.successCount,
    required this.failedCount,
    required this.existingFailedCount,
    required this.pendingCount,
    required this.needsReconciliationCount,
    required this.unresolvedCount,
    required this.stopped,
    required this.stopReason,
  });

  final int successCount;
  final int failedCount;
  final int existingFailedCount;
  final int pendingCount;
  final int needsReconciliationCount;
  final int unresolvedCount;
  final bool stopped;
  final String? stopReason;
}
