import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';

const offlineReconciliationCandidateTimeWindow = Duration(hours: 24);

bool isWithinOfflineReconciliationCandidateTimeWindow({
  required DateTime localCreatedAt,
  required DateTime? remoteCreatedAt,
}) {
  if (remoteCreatedAt == null) return false;
  final difference = remoteCreatedAt
      .toUtc()
      .difference(localCreatedAt.toUtc())
      .inMilliseconds
      .abs();
  return difference <= offlineReconciliationCandidateTimeWindow.inMilliseconds;
}

typedef AdminSessionVerifier = Future<AuthUser?> Function();

abstract interface class OfflineTransactionReconciliation {
  Future<List<TransactionRecord>> findCandidates({
    required String localId,
    required String activeOutletId,
    required AdminSessionVerifier verifyAdminSession,
  });

  Future<void> matchExistingRemote({
    required String localId,
    required String activeOutletId,
    required String remoteTransactionId,
    required String reason,
    required AdminSessionVerifier verifyAdminSession,
    String? notes,
  });

  Future<void> handleFailedOutsideServer({
    required String localId,
    required String activeOutletId,
    required String reason,
    required AdminSessionVerifier verifyAdminSession,
    String? notes,
  });
}
