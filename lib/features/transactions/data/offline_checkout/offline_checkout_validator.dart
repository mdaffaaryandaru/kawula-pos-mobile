import 'dart:convert';

import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/products/data/models/catalog_models.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/transactions/data/models/checkout_models.dart';
import 'package:kawula_pos/features/transactions/domain/exceptions/offline_checkout_exception.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

class OfflineCheckoutValidationResult {
  const OfflineCheckoutValidationResult({
    required this.outletId,
    required this.items,
    required this.itemDiscountAmounts,
    required this.settings,
    required this.paymentMethod,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.discountAmount,
    required this.changeAmount,
  });

  final String outletId;
  final List<CartItem> items;
  final List<num> itemDiscountAmounts;
  final CheckoutSettingsModel settings;
  final String paymentMethod;
  final num subtotal;
  final num taxAmount;
  final num total;
  final num discountAmount;
  final num changeAmount;
}

class OfflineCheckoutValidator {
  const OfflineCheckoutValidator({
    required this.user,
    required this.shift,
    required this.cache,
    required this.transactionsDao,
  });

  final AuthUser user;
  final ActiveShift shift;
  final OfflineMasterDataCache cache;
  final OfflineTransactionsDao transactionsDao;

  Future<OfflineCheckoutValidationResult> validate({
    required String outletId,
    required List<CartItem> items,
    required num serviceCharge,
    required String paymentMethod,
    required num paidAmount,
    required bool openBill,
  }) async {
    if (!canUseOfflineSales(user.role) ||
        cache.role != user.role ||
        !cache.shouldUseOfflineData) {
      throw StateError(
        'Checkout offline hanya tersedia untuk sesi Offline Sales yang sesuai.',
      );
    }

    final shiftOutletId = shift.outletId;
    if (shift.status.toLowerCase() != 'open' ||
        shiftOutletId == null ||
        shiftOutletId.isEmpty ||
        outletId != shiftOutletId ||
        !cache.isScoped ||
        cache.userId != user.id ||
        cache.outletId != shiftOutletId) {
      throw StateError(
        'Shift aktif yang sesuai untuk transaksi lokal tidak tersedia.',
      );
    }

    final rawProducts = await cache.read(
      cacheType: 'catalog_products',
      dataKey: 'all',
    );
    final rawSettings = await cache.read(
      cacheType: 'checkout_settings',
      dataKey: 'store',
    );
    final rawMethods = await cache.read(
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
    if (items.isEmpty) {
      throw const OfflineCheckoutException('Keranjang masih kosong.');
    }

    CheckoutPaymentMethodModel? selectedMethod;
    for (final method in methods) {
      if (method.code.toUpperCase() == paymentMethod.trim().toUpperCase()) {
        selectedMethod = method;
        break;
      }
    }
    if (!openBill && selectedMethod == null) {
      throw const OfflineCheckoutException(
        'Metode pembayaran tidak tersedia dalam cache checkout.',
      );
    }
    final storedPaymentMethod = openBill ? 'OPEN_BILL' : selectedMethod!.code;

    final unresolvedSales = await transactionsDao.getUnresolvedSales(
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
        throw const OfflineCheckoutException(
          'Kuantitas produk harus lebih dari nol.',
        );
      }
      final product = products[item.product.id];
      if (product == null || !product.isActive) {
        throw const OfflineCheckoutException(
          'Produk tidak tersedia pada cache katalog.',
        );
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
        throw const OfflineCheckoutException(
          'Estimasi stok produk tidak tersedia.',
        );
      }
      final available = stock - (alreadySold[entry.key] ?? 0);
      if (entry.value > available) {
        throw OfflineCheckoutException(
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
      throw const OfflineCheckoutException(
        'Biaya layanan tidak sesuai pengaturan checkout.',
      );
    }
    final total = (subtotal + taxAmount + serviceCharge).round();
    if (!openBill && (paidAmount < total || paidAmount < 0)) {
      throw const OfflineCheckoutException(
        'Nominal pembayaran tidak boleh kurang dari total transaksi.',
      );
    }
    if (openBill && paymentMethod.toUpperCase() != 'OPEN_BILL') {
      throw const OfflineCheckoutException(
        'Metode pembayaran Open Bill tidak valid.',
      );
    }

    final itemDiscountAmounts = validatedItems
        .map(
          (item) =>
              (item.product.price - item.product.discountedPrice) *
              item.quantity,
        )
        .toList(growable: false);
    final discountAmount = itemDiscountAmounts.fold<num>(
      0,
      (amount, itemDiscount) => amount + itemDiscount,
    );
    return OfflineCheckoutValidationResult(
      outletId: shiftOutletId,
      items: validatedItems,
      itemDiscountAmounts: itemDiscountAmounts,
      settings: settings,
      paymentMethod: storedPaymentMethod,
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
      discountAmount: discountAmount,
      changeAmount: openBill ? 0 : paidAmount - total,
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
      throw const OfflineCheckoutException(
        'Varian yang dipilih tidak sesuai katalog.',
      );
    }

    final validated = <SelectedProductVariant>[];
    for (final group in product.variantGroups) {
      final selected = selectedByGroup[group.name] ?? const [];
      if (selected.length < group.minSelection ||
          selected.length > group.maxSelection ||
          (group.isRequired && selected.isEmpty)) {
        throw OfflineCheckoutException(
          'Pilihan varian ${group.name} tidak valid.',
        );
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
          throw const OfflineCheckoutException(
            'Harga varian tidak sesuai katalog.',
          );
        }
        final selectionId = option.id ?? option.name;
        if (!selectedOptions.add(selectionId)) {
          throw const OfflineCheckoutException(
            'Varian yang sama dipilih lebih dari sekali.',
          );
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
}
