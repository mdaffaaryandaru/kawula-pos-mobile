// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/features/transactions/domain/services/offline_transaction_reconciliation.dart';

class AdminOfflineResolutionService
    implements OfflineTransactionReconciliation {
  const AdminOfflineResolutionService({
    required OfflineTransactionQueueRepository queueRepository,
    required CheckoutRepository checkoutRepository,
  }) : _queueRepository = queueRepository,
       _checkoutRepository = checkoutRepository;

  final OfflineTransactionQueueRepository _queueRepository;
  final CheckoutRepository _checkoutRepository;

  @override
  Future<List<TransactionRecord>> findCandidates({
    required String localId,
    required String activeOutletId,
    required AdminSessionVerifier verifyAdminSession,
  }) async {
    await _verifiedAdmin(verifyAdminSession);
    final local = await _getScopedResolvableTransaction(
      localId: localId,
      activeOutletId: activeOutletId,
    );
    final transactions = await _checkoutRepository.getTransactions();
    final candidates = transactions
        .where((transaction) => _matches(local, transaction))
        .toList();
    candidates.sort((a, b) {
      final timeComparison = _timeDistance(
        local,
        a,
      ).compareTo(_timeDistance(local, b));
      if (timeComparison != 0) return timeComparison;
      return a.id.compareTo(b.id);
    });
    return candidates;
  }

  @override
  Future<void> matchExistingRemote({
    required String localId,
    required String activeOutletId,
    required String remoteTransactionId,
    required String reason,
    required AdminSessionVerifier verifyAdminSession,
    String? notes,
  }) async {
    final admin = await _verifiedAdmin(verifyAdminSession);
    final local = await _getScopedResolvableTransaction(
      localId: localId,
      activeOutletId: activeOutletId,
      allowAlreadyResolved: true,
    );
    final transactions = await _checkoutRepository.getTransactions();
    final remote = transactions.where(
      (transaction) => transaction.id == remoteTransactionId,
    );
    if (remote.length != 1 || !_matches(local, remote.single)) {
      throw StateError(
        'Transaksi server tidak lagi memenuhi kriteria pencocokan.',
      );
    }

    final saved = await _queueRepository.resolveManually(
      localId: local.localId,
      outletId: activeOutletId,
      adminUserId: admin.id,
      adminRole: admin.role,
      resolutionType: 'matched_existing_remote',
      remoteTransactionId: remote.single.id,
      resolvedAt: DateTime.now(),
      reason: reason,
      notes: notes,
    );
    if (!saved) {
      throw StateError('Transaksi lokal sudah berubah atau tidak tersedia.');
    }
  }

  @override
  Future<void> handleFailedOutsideServer({
    required String localId,
    required String activeOutletId,
    required String reason,
    required AdminSessionVerifier verifyAdminSession,
    String? notes,
  }) async {
    final admin = await _verifiedAdmin(verifyAdminSession);
    final local = await _getScopedResolvableTransaction(
      localId: localId,
      activeOutletId: activeOutletId,
    );
    if (local.status != 'failed') {
      throw StateError(
        'Hanya transaksi yang ditolak secara pasti dapat ditangani di luar server.',
      );
    }

    final saved = await _queueRepository.resolveManually(
      localId: local.localId,
      outletId: activeOutletId,
      adminUserId: admin.id,
      adminRole: admin.role,
      resolutionType: 'handled_outside_server',
      resolvedAt: DateTime.now(),
      reason: reason,
      notes: notes,
    );
    if (!saved) {
      throw StateError('Transaksi lokal sudah berubah atau tidak tersedia.');
    }
  }

  Future<AuthUser> _verifiedAdmin(
    AdminSessionVerifier verifyAdminSession,
  ) async {
    final admin = await verifyAdminSession();
    if (admin == null ||
        admin.role != 'Admin' ||
        admin.isOfflineSession ||
        admin.id.trim().isEmpty) {
      throw StateError(
        'Verifikasi Admin online diperlukan untuk tindakan ini.',
      );
    }
    return admin;
  }

  Future<OfflineTransactionQueueItem> _getScopedResolvableTransaction({
    required String localId,
    required String activeOutletId,
    bool allowAlreadyResolved = false,
  }) async {
    if (activeOutletId.trim().isEmpty) {
      throw ArgumentError.value(activeOutletId, 'activeOutletId');
    }
    final transaction = await _queueRepository.getTransactionByLocalId(localId);
    final allowedStatuses = {
      'failed',
      'needs_reconciliation',
      if (allowAlreadyResolved) 'resolved_manually',
    };
    if (transaction == null ||
        transaction.outletId != activeOutletId ||
        !allowedStatuses.contains(transaction.status)) {
      throw StateError('Transaksi tidak tersedia dalam scope outlet aktif.');
    }
    return transaction;
  }

  bool _matches(OfflineTransactionQueueItem local, TransactionRecord remote) {
    if (remote.outletId != local.outletId ||
        remote.cashierId != local.ownerUserId ||
        remote.createdAt == null ||
        remote.paymentMethod.trim().toUpperCase() !=
            _localPaymentMethod(local).toUpperCase()) {
      return false;
    }

    final localItems = _localItemKeys(local);
    if (localItems == null || localItems.isEmpty) return false;
    final remoteItems = remote.items.map((item) {
      if (item.productId.isEmpty) return null;
      final variants =
          item.selectedVariants
              .map((variant) => '${variant.groupName}:${variant.optionName}')
              .toList()
            ..sort();
      return '${item.productId}:${item.quantity}:${variants.join('|')}';
    }).toList();
    if (remoteItems.any((item) => item == null)) return false;
    remoteItems.sort();
    return _sameValues(localItems, remoteItems.cast<String>().toList());
  }

  int _timeDistance(
    OfflineTransactionQueueItem local,
    TransactionRecord remote,
  ) => remote.createdAt!
      .toUtc()
      .difference(local.createdAtLocal.toUtc())
      .inMilliseconds
      .abs();

  String _localPaymentMethod(OfflineTransactionQueueItem local) {
    final payload = _decodeMap(local.payloadJson);
    final method = payload?['payment_method'];
    return method is String ? method.trim() : '';
  }

  List<String>? _localItemKeys(OfflineTransactionQueueItem local) {
    final payload = _decodeMap(local.payloadJson);
    final items = payload?['items'];
    if (items is! List) return null;
    final keys = <String>[];
    for (final item in items) {
      if (item is! Map ||
          item['product_id'] is! String ||
          item['quantity'] is! num) {
        return null;
      }
      final variants = item['selected_variants'] ?? const [];
      if (variants is! List) return null;
      final variantKeys = <String>[];
      for (final variant in variants) {
        if (variant is! Map ||
            variant['group_name'] is! String ||
            variant['option_name'] is! String) {
          return null;
        }
        variantKeys.add('${variant['group_name']}:${variant['option_name']}');
      }
      variantKeys.sort();
      keys.add(
        '${item['product_id']}:${(item['quantity'] as num).toInt()}:'
        '${variantKeys.join('|')}',
      );
    }
    keys.sort();
    return keys;
  }

  Map<String, dynamic>? _decodeMap(String json) {
    final decoded = jsonDecode(json);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  bool _sameValues(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    first.sort();
    second.sort();
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}
