import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

class CashierOfflineSyncSummary {
  const CashierOfflineSyncSummary({
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

enum _SyncResult {
  success,
  failed,
  needsReconciliation,
  stopPin,
  stopAuthentication,
  stopAuthorization,
}

class CashierOfflineSyncService {
  CashierOfflineSyncService(
    this._repository,
    this._dao, {
    required this._activeShiftsRepository,
  });

  final CheckoutRepository _repository;
  final OfflineTransactionsDao _dao;
  final ShiftsRepository _activeShiftsRepository;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<CashierOfflineSyncSummary> syncForCashier({
    required String ownerUserId,
    required String outletId,
    required String role,
    required String pin,
  }) async {
    if (!canUseOfflineSales(role)) {
      throw StateError('Role tidak diizinkan melakukan Offline Sales.');
    }
    if (ownerUserId.trim().isEmpty) {
      throw ArgumentError.value(
        ownerUserId,
        'ownerUserId',
        'Pemilik antrean wajib ditentukan.',
      );
    }
    if (outletId.trim().isEmpty) {
      throw ArgumentError.value(
        outletId,
        'outletId',
        'Outlet aktif wajib ditentukan.',
      );
    }
    if (pin.trim().isEmpty) {
      throw ArgumentError.value(
        pin,
        'pin',
        'PIN wajib dimasukkan untuk sinkronisasi.',
      );
    }
    if (_isSyncing) {
      final queue = await _dao.getUnresolvedByOwnerAndOutlet(
        ownerUserId: ownerUserId,
        outletId: outletId,
      );
      return _summaryFor(
        queue,
        stopped: true,
        stopReason: 'Sinkronisasi lain sedang berjalan.',
      );
    }

    _isSyncing = true;
    var successCount = 0;
    var failedCount = 0;
    String? stopReason;

    try {
      var queue = await _dao.getUnresolvedByOwnerAndOutlet(
        ownerUserId: ownerUserId,
        outletId: outletId,
      );
      if (queue.isEmpty) {
        return _summaryFor(queue, stopped: false, stopReason: null);
      }

      final existingFailedCount = queue
          .where(
            (transaction) =>
                transaction.status ==
                OfflineTransactionStatus.failed.databaseValue,
          )
          .length;
      final stuckSyncing = queue
          .where(
            (transaction) =>
                transaction.status ==
                OfflineTransactionStatus.syncing.databaseValue,
          )
          .toList(growable: false);
      for (final transaction in stuckSyncing) {
        await _dao.updateTransactionStatus(
          localId: transaction.localId,
          status: OfflineTransactionStatus.needsReconciliation,
          lastError: 'Proses sinkronisasi sebelumnya terputus saat transaksi berstatus syncing. Verifikasi transaksi di server sebelum tindakan lanjutan.',
        );
      }

      queue = await _dao.getUnresolvedByOwnerAndOutlet(
        ownerUserId: ownerUserId,
        outletId: outletId,
      );
      final needsReconciliation = queue
          .where(
            (transaction) =>
                transaction.status ==
                OfflineTransactionStatus.needsReconciliation.databaseValue,
          )
          .toList(growable: false);
      if (needsReconciliation.isNotEmpty) {
        return _summaryFor(
          queue,
          existingFailedCount: existingFailedCount,
          stopped: true,
          stopReason: 'Terdapat transaksi yang menunggu rekonsiliasi.',
        );
      }

      final pendingRecords = queue
          .where(
            (transaction) =>
                transaction.status ==
                OfflineTransactionStatus.pendingSync.databaseValue,
          )
          .toList(growable: false);

      if (pendingRecords.isNotEmpty) {
        try {
          final activeShift = await _activeShiftsRepository.getActive();
          if (activeShift == null ||
              activeShift.status.toLowerCase() != 'open' ||
              activeShift.outletId != outletId ||
              activeShift.isOfflineSnapshot) {
            return _summaryFor(
              queue,
              existingFailedCount: existingFailedCount,
              stopped: true,
              stopReason: 'Sinkronisasi memerlukan shift aktif online pada outlet yang sedang dipakai. Shift asal transaksi tetap tersimpan sebagai riwayat.',
            );
          }
        } catch (error) {
          return _summaryFor(
            queue,
            existingFailedCount: existingFailedCount,
            stopped: true,
            stopReason: 'Shift aktif server belum dapat diverifikasi: $error',
          );
        }
      }

      for (final record in pendingRecords) {
        final payload = _decodePayload(record.payloadJson);
        if (payload == null) {
          await _dao.updateTransactionStatus(
            localId: record.localId,
            status: OfflineTransactionStatus.failed,
            lastError: 'Payload transaksi lokal tidak valid.',
          );
          failedCount++;
          continue;
        }

        await _dao.updateTransactionStatus(
          localId: record.localId,
          status: OfflineTransactionStatus.syncing,
          incrementAttemptCount: true,
        );

        final result = await _sendRecord(record, payload, pin);
        switch (result) {
          case _SyncResult.success:
            successCount++;
            break;
          case _SyncResult.failed:
            failedCount++;
            break;
          case _SyncResult.needsReconciliation:
            stopReason =
                'Respons server tidak dapat dipastikan dan antrean dihentikan.';
            break;
          case _SyncResult.stopPin:
            stopReason = 'PIN ditolak. Masukkan PIN yang benar untuk mencoba kembali.';
            break;
          case _SyncResult.stopAuthentication:
            stopReason = 'Sesi autentikasi kedaluwarsa.';
            break;
          case _SyncResult.stopAuthorization:
            stopReason = 'Akses ditolak oleh server.';
            break;
        }

        if (result != _SyncResult.success && result != _SyncResult.failed) {
          break;
        }
      }

      final remainingQueue = await _dao.getUnresolvedByOwnerAndOutlet(
        ownerUserId: ownerUserId,
        outletId: outletId,
      );
      return _summaryFor(
        remainingQueue,
        successCount: successCount,
        failedCount: failedCount,
        existingFailedCount: existingFailedCount,
        stopped: stopReason != null,
        stopReason: stopReason,
      );
    } finally {
      _isSyncing = false;
    }
  }

  CashierOfflineSyncSummary _summaryFor(
    List<OfflineTransaction> queue, {
    int successCount = 0,
    int failedCount = 0,
    int? existingFailedCount,
    required bool stopped,
    required String? stopReason,
  }) => CashierOfflineSyncSummary(
    successCount: successCount,
    failedCount: failedCount,
    existingFailedCount:
        existingFailedCount ??
        queue
            .where(
              (transaction) =>
                  transaction.status ==
                  OfflineTransactionStatus.failed.databaseValue,
            )
            .length,
    pendingCount: queue
        .where(
          (transaction) =>
              transaction.status ==
              OfflineTransactionStatus.pendingSync.databaseValue,
        )
        .length,
    needsReconciliationCount: queue
        .where(
          (transaction) =>
              transaction.status ==
              OfflineTransactionStatus.needsReconciliation.databaseValue,
        )
        .length,
    unresolvedCount: queue.length,
    stopped: stopped,
    stopReason: stopReason,
  );

  Future<_SyncResult> _sendRecord(
    OfflineTransaction transaction,
    Map<String, dynamic> payload,
    String pin,
  ) async {
    final items = _buildCartItems(payload['items']);
    final totalAmount = _asNum(payload['total_amount']) ?? 0;
    final serviceCharge = _asNum(payload['service_charge']) ?? 0;
    final paymentMethod = _asString(payload['payment_method']) ?? 'CASH';
    final paidAmount = _asNum(payload['paid_amount']) ?? 0;
    final openBill =
        transaction.transactionType == 'open_bill' ||
        paymentMethod.toUpperCase() == 'OPEN_BILL';

    try {
      final result = await _repository.createTransaction(
        outletId: transaction.outletId,
        items: items,
        estimatedTotal: totalAmount,
        serviceCharge: serviceCharge,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        pin: openBill ? null : pin,
        openBill: openBill,
        memberId: _asString(payload['member_id']),
        tableNumber: _asString(payload['table_number']),
      );

      final remoteId = result.id.trim();
      if (remoteId.isEmpty || remoteId.startsWith('OFF-')) {
        await _dao.updateTransactionStatus(
          localId: transaction.localId,
          status: OfflineTransactionStatus.needsReconciliation,
          lastError: 'Respons server tidak menyertakan ID transaksi remote yang valid.',
        );
        return _SyncResult.needsReconciliation;
      }

      await _dao.updateTransactionStatus(
        localId: transaction.localId,
        status: OfflineTransactionStatus.synced,
        remoteTransactionId: remoteId,
        lastError: null,
      );
      return _SyncResult.success;
    } on ApiException catch (error) {
      final message = error.message.toLowerCase();
      if (error.statusCode == 401) {
        await _dao.updateTransactionStatus(
          localId: transaction.localId,
          status: OfflineTransactionStatus.pendingSync,
          lastError: 'Sesi autentikasi kedaluwarsa. Sinkronisasi dihentikan.',
        );
        return _SyncResult.stopAuthentication;
      }
      if (error.statusCode == 403) {
        await _dao.updateTransactionStatus(
          localId: transaction.localId,
          status: OfflineTransactionStatus.pendingSync,
          lastError: 'Akses ditolak oleh server. Sinkronisasi dihentikan.',
        );
        return _SyncResult.stopAuthorization;
      }
      if (message.contains('pin')) {
        await _dao.updateTransactionStatus(
          localId: transaction.localId,
          status: OfflineTransactionStatus.pendingSync,
          lastError: 'PIN kasir ditolak. Sinkronisasi dihentikan.',
        );
        return _SyncResult.stopPin;
      }
      if (error.statusCode == 400) {
        await _dao.updateTransactionStatus(
          localId: transaction.localId,
          status: OfflineTransactionStatus.failed,
          lastError: error.message,
        );
        return _SyncResult.failed;
      }
      await _dao.updateTransactionStatus(
        localId: transaction.localId,
        status: OfflineTransactionStatus.needsReconciliation,
        lastError: error.message,
      );
      return _SyncResult.needsReconciliation;
    } on http.ClientException catch (error) {
      await _dao.updateTransactionStatus(
        localId: transaction.localId,
        status: OfflineTransactionStatus.needsReconciliation,
        lastError: error.toString(),
      );
      return _SyncResult.needsReconciliation;
    } on TimeoutException catch (error) {
      await _dao.updateTransactionStatus(
        localId: transaction.localId,
        status: OfflineTransactionStatus.needsReconciliation,
        lastError: error.toString(),
      );
      return _SyncResult.needsReconciliation;
    } catch (error) {
      await _dao.updateTransactionStatus(
        localId: transaction.localId,
        status: OfflineTransactionStatus.needsReconciliation,
        lastError: error.toString(),
      );
      return _SyncResult.needsReconciliation;
    }
  }

  Map<String, dynamic>? _decodePayload(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  List<CartItem> _buildCartItems(Object? rawItems) {
    if (rawItems is! List) {
      throw const FormatException('Payload item transaksi tidak valid.');
    }

    final items = <CartItem>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) {
        throw const FormatException('Item transaksi lokal tidak valid.');
      }
      final productId = rawItem['product_id'];
      final quantity = rawItem['quantity'];
      if (productId is! String || quantity is! num) {
        throw const FormatException(
          'Rincian item transaksi lokal tidak valid.',
        );
      }
      final product = CatalogProduct(
        id: productId,
        name: rawItem['product_name'] is String
            ? rawItem['product_name'] as String
            : productId,
        price: _asNum(rawItem['unit_price']) ?? 0,
        imageUrl: '',
        isActive: true,
        category: null,
        variantGroups: const [],
      );
      final selectedVariants = <SelectedProductVariant>[];
      final variantPayload = rawItem['selected_variants'];
      if (variantPayload is List) {
        for (final rawVariant in variantPayload) {
          if (rawVariant is! Map<String, dynamic>) {
            continue;
          }
          selectedVariants.add(
            SelectedProductVariant(
              groupName: _asString(rawVariant['group_name']) ?? '',
              optionName: _asString(rawVariant['option_name']) ?? '',
              optionId: _asString(rawVariant['option_id']),
              priceAdjustment: _asNum(rawVariant['price_adjustment']) ?? 0,
            ),
          );
        }
      }

      items.add(
        CartItem(
          product: product,
          quantity: quantity.toInt(),
          selectedVariants: selectedVariants,
          notes: rawItem['notes'] is String ? rawItem['notes'] as String : '',
        ),
      );
    }
    return items;
  }

  String? _asString(Object? value) => value is String ? value : null;

  num? _asNum(Object? value) => value is num ? value : null;
}
