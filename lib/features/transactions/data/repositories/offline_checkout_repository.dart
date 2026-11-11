import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/members/domain/entities/member_reward_claim.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/network/platform_network_exception.dart';
import 'package:kawula_pos/features/transactions/data/offline_checkout/offline_checkout_payload_builder.dart';
import 'package:kawula_pos/features/transactions/data/offline_checkout/offline_checkout_validator.dart';
import 'package:kawula_pos/features/transactions/data/offline_checkout/offline_receipt_snapshot_builder.dart';

class OfflineCheckoutRepository
    implements CheckoutRepository, CheckoutModeProvider {
  OfflineCheckoutRepository(
    CheckoutRepository delegate,
    OfflineMasterDataCache cache,
    OfflineTransactionsDao transactionsDao, {
    required AuthUser user,
    required ActiveShift shift,
  }) : _delegate = delegate,
       _cache = cache,
       _offlineTransactionsDao = transactionsDao,
       user = user,
       shift = shift,
       _validator = OfflineCheckoutValidator(
         user: user,
         shift: shift,
         cache: cache,
         transactionsDao: transactionsDao,
       );

  static const Uuid _uuid = Uuid();

  final CheckoutRepository _delegate;
  final OfflineMasterDataCache _cache;
  final OfflineTransactionsDao _offlineTransactionsDao;
  final AuthUser user;
  final ActiveShift shift;
  final OfflineCheckoutValidator _validator;

  @override
  bool get isOffline => _cache.shouldUseOfflineData;

  @override
  Future<List<CheckoutPaymentMethod>> getPaymentMethods() =>
      _delegate.getPaymentMethods();

  @override
  Future<CheckoutSettings> getSettings() => _delegate.getSettings();

  @override
  Future<List<Member>> searchMembers(String search) =>
      _delegate.searchMembers(search);

  @override
  Future<List<TransactionRecord>> getTransactions() async {
    List<TransactionRecord> serverTransactions = const [];
    if (!isOffline) {
      try {
        serverTransactions = await _delegate.getTransactions();
        _cache.markOnline();
      } on http.ClientException {
        _cache.markOffline();
      } on TimeoutException {
        _cache.markOffline();
      } on Exception catch (error) {
        if (!isPlatformNetworkException(error)) rethrow;
        _cache.markOffline();
      }
    }

    final localTransactions = await _offlineTransactionsDao
        .getTransactionsByOwner(user.id);
    final localBills = localTransactions
        .where(
          (transaction) =>
              transaction.outletId == shift.outletId &&
              transaction.transactionType == 'open_bill' &&
              transaction.status !=
                  OfflineTransactionStatus.synced.databaseValue,
        )
        .map(_toLocalOpenBill)
        .toList(growable: false);
    return [...serverTransactions, ...localBills];
  }

  TransactionRecord _toLocalOpenBill(OfflineTransaction transaction) {
    final receipt = jsonDecode(transaction.receiptSnapshotJson);
    if (receipt is! Map<String, dynamic> || receipt['items'] is! List) {
      throw const FormatException('Snapshot Open Bill lokal tidak valid.');
    }
    final items = (receipt['items'] as List)
        .map((item) {
          if (item is! Map<String, dynamic> ||
              item['product_name'] is! String ||
              item['quantity'] is! num ||
              item['unit_price'] is! num) {
            throw const FormatException('Rincian Open Bill lokal tidak valid.');
          }
          final variants = item['selected_variants'];
          return TransactionRecordItem(
            productName: item['product_name'] as String,
            quantity: (item['quantity'] as num).toInt(),
            price: item['unit_price'] as num,
            notes: item['notes'] is String ? item['notes'] as String : '',
            selectedVariants: variants is List
                ? variants
                      .whereType<Map<String, dynamic>>()
                      .map(
                        (variant) => CheckoutResultVariant(
                          groupName: variant['group_name'] as String,
                          optionName: variant['option_name'] as String,
                        ),
                      )
                      .toList(growable: false)
                : const [],
          );
        })
        .toList(growable: false);
    final total = receipt['total_amount'];
    if (total is! num) {
      throw const FormatException('Total Open Bill lokal tidak valid.');
    }

    return TransactionRecord(
      id: transaction.localId,
      status: 'offline_open_bill',
      totalAmount: total,
      paymentMethod: 'OPEN_BILL',
      paidAmount: 0,
      changeAmount: 0,
      createdAt: transaction.createdAtLocal,
      items: items,
      subtotal: receipt['subtotal'] is num ? receipt['subtotal'] as num : 0,
      taxAmount: receipt['tax_amount'] is num
          ? receipt['tax_amount'] as num
          : 0,
      serviceCharge: receipt['service_charge'] is num
          ? receipt['service_charge'] as num
          : 0,
      discountAmount: receipt['discount_amount'] is num
          ? receipt['discount_amount'] as num
          : 0,
      outletName: receipt['outlet_name'] is String
          ? receipt['outlet_name'] as String
          : '',
      cashierName: receipt['cashier_name'] is String
          ? receipt['cashier_name'] as String
          : user.name,
      memberName: receipt['member_name'] is String
          ? receipt['member_name'] as String
          : '',
      tableNumber: receipt['table_number'] is String
          ? receipt['table_number'] as String
          : '',
      notes: 'BELUM TERSINKRON',
    );
  }

  @override
  Future<CheckoutResult> createTransaction({
    required String outletId,
    required List<CartItem> items,
    required num estimatedTotal,
    required num serviceCharge,
    required String paymentMethod,
    required num paidAmount,
    required String? pin,
    required bool openBill,
    String? memberId,
    String? tableNumber,
  }) async {
    if (isOffline) {
      return _saveOfflineTransaction(
        outletId: outletId,
        items: items,
        serviceCharge: serviceCharge,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        openBill: openBill,
        memberId: memberId,
        tableNumber: tableNumber,
        status: OfflineTransactionStatus.pendingSync,
      );
    }

    try {
      final result = await _delegate.createTransaction(
        outletId: outletId,
        items: items,
        estimatedTotal: estimatedTotal,
        serviceCharge: serviceCharge,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        pin: pin,
        openBill: openBill,
        memberId: memberId,
        tableNumber: tableNumber,
      );
      _cache.markOnline();
      return result;
    } on http.ClientException catch (error) {
      _cache.markOffline();
      return _saveAfterUnknownServerOutcome(
        outletId: outletId,
        items: items,
        serviceCharge: serviceCharge,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        openBill: openBill,
        memberId: memberId,
        tableNumber: tableNumber,
        lastError: error.toString(),
      );
    } on TimeoutException catch (error) {
      _cache.markOffline();
      return _saveAfterUnknownServerOutcome(
        outletId: outletId,
        items: items,
        serviceCharge: serviceCharge,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        openBill: openBill,
        memberId: memberId,
        tableNumber: tableNumber,
        lastError: error.toString(),
      );
    } on Exception catch (error) {
      if (!isPlatformNetworkException(error)) rethrow;
      _cache.markOffline();
      return _saveAfterUnknownServerOutcome(
        outletId: outletId,
        items: items,
        serviceCharge: serviceCharge,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        openBill: openBill,
        memberId: memberId,
        tableNumber: tableNumber,
        lastError: error.toString(),
      );
    }
  }

  Future<CheckoutResult> _saveAfterUnknownServerOutcome({
    required String outletId,
    required List<CartItem> items,
    required num serviceCharge,
    required String paymentMethod,
    required num paidAmount,
    required bool openBill,
    required String? memberId,
    required String? tableNumber,
    required String lastError,
  }) => _saveOfflineTransaction(
    outletId: outletId,
    items: items,
    serviceCharge: serviceCharge,
    paymentMethod: paymentMethod,
    paidAmount: paidAmount,
    openBill: openBill,
    memberId: memberId,
    tableNumber: tableNumber,
    status: OfflineTransactionStatus.needsReconciliation,
    lastError: lastError,
  );

  Future<CheckoutResult> _saveOfflineTransaction({
    required String outletId,
    required List<CartItem> items,
    required num serviceCharge,
    required String paymentMethod,
    required num paidAmount,
    required bool openBill,
    required String? memberId,
    required String? tableNumber,
    required OfflineTransactionStatus status,
    String? lastError,
  }) async {
    final checkout = await _validator.validate(
      outletId: outletId,
      items: items,
      serviceCharge: serviceCharge,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      openBill: openBill,
    );
    final createdAt = DateTime.now();
    final localId = 'OFF-${_uuid.v4()}';
    final syncMarker = 'OFFLINE_SYNC:${_uuid.v4()}';
    final payload = const OfflineCheckoutPayloadBuilder().build(
      outletId: checkout.outletId,
      items: checkout.items,
      total: checkout.total,
      serviceCharge: serviceCharge,
      paymentMethod: checkout.paymentMethod,
      memberId: memberId,
      tableNumber: tableNumber,
      openBill: openBill,
      paidAmount: paidAmount,
    );
    final receiptSnapshot = const OfflineReceiptSnapshotBuilder().build(
      checkout: checkout,
      user: user,
      shift: shift,
      localId: localId,
      syncMarker: syncMarker,
      status: status,
      createdAt: createdAt,
      memberId: memberId,
      tableNumber: tableNumber,
      openBill: openBill,
      paidAmount: paidAmount,
      serviceCharge: serviceCharge,
    );

    await _offlineTransactionsDao.saveOfflineTransaction(
      ownerUserId: user.id,
      outletId: checkout.outletId,
      shiftId: shift.id,
      transactionType: openBill ? 'open_bill' : 'sale',
      payload: payload,
      receiptSnapshot: receiptSnapshot,
      createdAtLocal: createdAt,
      localId: localId,
      syncMarker: syncMarker,
      status: status,
      lastError: lastError,
    );

    return CheckoutResult(
      id: localId,
      status: status.databaseValue,
      totalAmount: checkout.total,
      paymentMethod: checkout.paymentMethod,
      paidAmount: openBill ? 0 : paidAmount,
      changeAmount: checkout.changeAmount,
      createdAt: createdAt,
      subtotal: checkout.subtotal,
      taxAmount: checkout.taxAmount,
      serviceCharge: serviceCharge,
      discountAmount: checkout.discountAmount,
      items: [
        for (final item in checkout.items)
          CheckoutResultItem(
            productName: item.product.name,
            quantity: item.quantity,
            price: item.unitPrice,
            selectedVariants: [
              for (final variant in item.selectedVariants)
                CheckoutResultVariant(
                  groupName: variant.groupName,
                  optionName: variant.optionName,
                ),
            ],
            notes: item.notes,
          ),
      ],
      notes: status == OfflineTransactionStatus.needsReconciliation
          ? 'Status server belum dapat dipastikan: $lastError'
          : 'BELUM TERSINKRON',
      tableNumber: tableNumber ?? '',
      isOffline: true,
      isOpenBill: openBill,
      outletName: shift.outletName ?? '',
      cashierName: user.name,
    );
  }

  @override
  Future<TransactionRecord> getTransaction(String transactionId) {
    _rejectLocalTransaction(transactionId);
    return _delegate.getTransaction(transactionId);
  }

  @override
  Future<TransactionRecord> cancelTransaction({
    required String transactionId,
    required String reason,
  }) {
    _rejectLocalTransaction(transactionId);
    return _delegate.cancelTransaction(
      transactionId: transactionId,
      reason: reason,
    );
  }

  @override
  Future<TransactionRecord> refundTransaction({
    required String transactionId,
    required String pin,
    required String reason,
  }) {
    _rejectLocalTransaction(transactionId);
    return _delegate.refundTransaction(
      transactionId: transactionId,
      pin: pin,
      reason: reason,
    );
  }

  @override
  Future<CheckoutResult> payPendingTransaction({
    required String transactionId,
    required String paymentMethod,
    required num paidAmount,
    required String pin,
  }) {
    _rejectLocalTransaction(transactionId);
    return _delegate.payPendingTransaction(
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      pin: pin,
    );
  }

  void _rejectLocalTransaction(String transactionId) {
    if (transactionId.startsWith('OFF-')) {
      throw StateError('Transaksi lokal belum dapat diproses melalui server.');
    }
  }

  @override
  Future<MemberRewardClaim> claimMemberReward(String memberId) =>
      _delegate.claimMemberReward(memberId);
}
