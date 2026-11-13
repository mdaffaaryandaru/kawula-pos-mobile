import 'package:kawula_pos/features/offline/domain/entities/offline_transaction_sync_summary.dart';

abstract interface class OfflineTransactionSync {
  bool get isSyncing;

  Future<OfflineTransactionSyncSummary> syncOfflineTransactions({
    required String ownerUserId,
    required String outletId,
    required String role,
    required String pin,
  });
}
