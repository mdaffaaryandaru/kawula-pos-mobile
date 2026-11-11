import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/members/domain/entities/member_reward_claim.dart';
import 'package:kawula_pos/features/products/data/models/catalog_models.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/transactions/data/models/checkout_models.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/network/platform_network_exception.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

class CashierOfflineCheckoutRepository
    implements CheckoutRepository, CheckoutModeProvider {
  CashierOfflineCheckoutRepository(
    this._delegate,
    this._cache,
    this._offlineTransactionsDao, {
    required this.user,
    required this.shift,
  });

  static const Uuid _uuid = Uuid();

  final CheckoutRepository _delegate;
  final CashierMasterDataCache _cache;
  final OfflineTransactionsDao _offlineTransactionsDao;
  final AuthUser user;
  final ActiveShift shift;

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
    if (!canUseOfflineSales(user.role) ||
        _cache.role != user.role ||
        !_cache.shouldUseOfflineData) {
      throw StateError(
        'Checkout offline hanya tersedia untuk sesi Offline Sales yang sesuai.',
      );
    }

    final shiftOutletId = shift.outletId;
    if (shift.status.toLowerCase() != 'open' ||
        shiftOutletId == null ||
        shiftOutletId.isEmpty ||
        outletId != shiftOutletId ||
        !_cache.isScoped ||
        _cache.userId != user.id ||
        _cache.outletId != shiftOutletId) {
      throw StateError(
        'Shift aktif yang sesuai untuk transaksi lokal tidak tersedia.',
      );
    }

    final rawProducts = await _cache.read(
      cacheType: 'catalog_products',
      dataKey: 'all',
    );
    final rawSettings = await _cache.read(
      cacheType: 'checkout_settings',
      dataKey: 'store',
    );
    final rawMethods = await _cache.read(
      cacheType: 'checkout_payment_methods',
      dataKey: 'active',
    );
    if (rawProducts is! List ||
        rawSettings is! Map<String, dynamic> ||
        rawMethods is! List) {
      throw StateError('Data checkout belum tersedia di cache lokal.');
    }

    final products = <String, CatalogProduct>{};
    for (final rawProduct in rawProducts) {
      if (rawProduct is! Map<String, dynamic>) {
        throw const FormatException('Cache katalog produk tidak valid.');
      }
      final product = CatalogProductModel.fromJson(rawProduct);
      products[product.id] = product;
    }
    final settings = CheckoutSettingsModel.fromJson(rawSettings);
    final methods = rawMethods
        .whereType<Map<String, dynamic>>()
        .map(CheckoutPaymentMethodModel.fromJson)
        .toList(growable: false);
    if (items.isEmpty) throw StateError('Keranjang masih kosong.');

    CheckoutPaymentMethodModel? selectedMethod;
    for (final method in methods) {
      if (method.code.toUpperCase() == paymentMethod.trim().toUpperCase()) {
        selectedMethod = method;
        break;
      }
    }
    if (!openBill && selectedMethod == null) {
      throw StateError(
        'Metode pembayaran tidak tersedia dalam cache checkout.',
      );
    }
    final storedPaymentMethod = openBill ? 'OPEN_BILL' : selectedMethod!.code;

    final unresolvedSales = await _offlineTransactionsDao.getUnresolvedSales(
      ownerUserId: user.id,
      outletId: shiftOutletId,
    );
    final alreadySold = <String, int>{};
    for (final transaction in unresolvedSales) {
      final payload = jsonDecode(transaction.payloadJson);
      if (payload is! Map<String, dynamic> || payload['items'] is! List) {
        continue;
      }
      for (final rawItem in payload['items'] as List) {
        if (rawItem is! Map<String, dynamic>) continue;
        final productId = rawItem['product_id'];
        final quantity = rawItem['quantity'];
        if (productId is String && quantity is num && quantity > 0) {
          alreadySold.update(
            productId,
            (value) => value + quantity.toInt(),
            ifAbsent: () => quantity.toInt(),
          );
        }
      }
    }

    final validatedItems = <CartItem>[];
    final quantitiesByProduct = <String, int>{};
    for (final item in items) {
      if (item.quantity <= 0) {
        throw StateError('Kuantitas produk harus lebih dari nol.');
      }
      final product = products[item.product.id];
      if (product == null || !product.isActive) {
        throw StateError('Produk tidak tersedia pada cache katalog.');
      }
      final validatedVariants = _validateVariants(
        product,
        item.selectedVariants,
      );
      final validatedItem = CartItem(
        product: product,
        quantity: item.quantity,
        selectedVariants: validatedVariants,
        notes: item.notes,
      );
      validatedItems.add(validatedItem);
      quantitiesByProduct.update(
        product.id,
        (quantity) => quantity + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    for (final entry in quantitiesByProduct.entries) {
      final stock = products[entry.key]!.stock;
      if (stock == null || !stock.isFinite || stock < 0) {
        throw StateError('Estimasi stok produk tidak tersedia.');
      }
      final available = stock - (alreadySold[entry.key] ?? 0);
      if (entry.value > available) {
        throw StateError(
          'Estimasi stok ${products[entry.key]!.name} tidak mencukupi. '
          'Stok aktual harus diverifikasi server.',
        );
      }
    }

    final subtotal = validatedItems.fold<num>(
      0,
      (total, item) => total + item.unitPrice * item.quantity,
    );
    final taxAmount = (subtotal * settings.taxPercentage / 100).round();
    if (serviceCharge != 0 && serviceCharge != settings.serviceCharge) {
      throw StateError('Biaya layanan tidak sesuai pengaturan checkout.');
    }
    final total = (subtotal + taxAmount + serviceCharge).round();
    if (!openBill && (paidAmount < total || paidAmount < 0)) {
      throw StateError(
        'Nominal pembayaran tidak boleh kurang dari total transaksi.',
      );
    }
    if (openBill && paymentMethod.toUpperCase() != 'OPEN_BILL') {
      throw StateError('Metode pembayaran Open Bill tidak valid.');
    }

    final createdAt = DateTime.now();
    final localId = 'OFF-${_uuid.v4()}';
    final syncMarker = 'OFFLINE_SYNC:${_uuid.v4()}';
    final discountAmount = validatedItems.fold<num>(
      0,
      (amount, item) =>
          amount +
          (item.product.price - item.product.discountedPrice) * item.quantity,
    );
    final changeAmount = openBill ? 0 : paidAmount - total;
    final payload = <String, Object?>{
      'outlet_id': shiftOutletId,
      'items': validatedItems
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
              'selected_variants': item.selectedVariants
                  .map(
                    (variant) => {
                      'group_name': variant.groupName,
                      'option_name': variant.optionName,
                      if (variant.optionId != null)
                        'option_id': variant.optionId,
                    },
                  )
                  .toList(growable: false),
              if (item.notes.trim().isNotEmpty) 'notes': item.notes.trim(),
            },
          )
          .toList(growable: false),
      'total_amount': total,
      'service_charge': serviceCharge,
      'payment_method': storedPaymentMethod,
      if (memberId != null && memberId.isNotEmpty) 'member_id': memberId,
      if (tableNumber != null && tableNumber.trim().isNotEmpty)
        'table_number': tableNumber.trim(),
      if (openBill) 'status': 'pending',
      if (!openBill) 'paid_amount': paidAmount,
    };
    final receiptSnapshot = <String, Object?>{
      'transaction_id': localId,
      'status': status.databaseValue,
      'store_name': settings.storeName.isEmpty ? 'Kawula' : settings.storeName,
      'address': settings.address,
      'logo_url': settings.logoUrl,
      'outlet_id': shiftOutletId,
      'outlet_name': shift.outletName ?? '',
      'cashier_id': user.id,
      'cashier_name': user.name,
      'created_at_local': createdAt.toIso8601String(),
      'items': validatedItems
          .map(
            (item) => {
              'product_id': item.product.id,
              'product_name': item.product.name,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'discount_amount':
                  (item.product.price - item.product.discountedPrice) *
                  item.quantity,
              'notes': item.notes,
              'selected_variants': item.selectedVariants
                  .map(
                    (variant) => {
                      'group_name': variant.groupName,
                      'option_name': variant.optionName,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'service_charge': serviceCharge,
      'discount_amount': discountAmount,
      'total_amount': total,
      'payment_method': storedPaymentMethod,
      'paid_amount': openBill ? 0 : paidAmount,
      'change_amount': changeAmount,
      'member_id': memberId,
      'member_name': '',
      'table_number': tableNumber ?? '',
      'sync_marker': syncMarker,
      'sync_status': status.databaseValue,
    };

    await _offlineTransactionsDao.saveOfflineTransaction(
      ownerUserId: user.id,
      outletId: shiftOutletId,
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
      totalAmount: total,
      paymentMethod: storedPaymentMethod,
      paidAmount: openBill ? 0 : paidAmount,
      changeAmount: changeAmount,
      createdAt: createdAt,
      subtotal: subtotal,
      taxAmount: taxAmount,
      serviceCharge: serviceCharge,
      discountAmount: discountAmount,
      items: [
        for (final item in validatedItems)
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

  List<SelectedProductVariant> _validateVariants(
    CatalogProduct product,
    List<SelectedProductVariant> selectedVariants,
  ) {
    final selectedByGroup = <String, List<SelectedProductVariant>>{};
    for (final variant in selectedVariants) {
      selectedByGroup.putIfAbsent(variant.groupName, () => []).add(variant);
    }
    if (selectedByGroup.keys.any(
      (groupName) =>
          !product.variantGroups.any((group) => group.name == groupName),
    )) {
      throw StateError('Varian yang dipilih tidak sesuai katalog.');
    }

    final validated = <SelectedProductVariant>[];
    for (final group in product.variantGroups) {
      final selected = selectedByGroup[group.name] ?? const [];
      if (selected.length < group.minSelection ||
          selected.length > group.maxSelection ||
          (group.isRequired && selected.isEmpty)) {
        throw StateError('Pilihan varian ${group.name} tidak valid.');
      }
      final selectedOptions = <String>{};
      for (final variant in selected) {
        ProductVariantOption? option;
        for (final candidate in group.options) {
          if (variant.optionId != null
              ? candidate.id == variant.optionId
              : candidate.name == variant.optionName) {
            option = candidate;
            break;
          }
        }
        if (option == null ||
            option.name != variant.optionName ||
            option.priceAdjustment != variant.priceAdjustment) {
          throw StateError('Harga varian tidak sesuai katalog.');
        }
        final selectionId = option.id ?? option.name;
        if (!selectedOptions.add(selectionId)) {
          throw StateError('Varian yang sama dipilih lebih dari sekali.');
        }
        validated.add(
          SelectedProductVariant(
            groupName: group.name,
            optionName: option.name,
            optionId: option.id,
            priceAdjustment: option.priceAdjustment,
          ),
        );
      }
    }
    return validated;
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
