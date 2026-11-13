import 'dart:convert';

import 'package:kawula_pos/features/offline/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/transactions/presentation/models/transaction_receipt_data.dart';

Map<String, dynamic> parseOfflineReceiptSnapshot(String receiptSnapshotJson) {
  try {
    final decoded = jsonDecode(receiptSnapshotJson);
    return decoded is Map<String, dynamic> ? decoded : const {};
  } on FormatException {
    return const {};
  }
}

TransactionReceiptData? buildOfflineReceiptData(
  OfflineTransactionQueueItem record,
) {
  final snapshot = parseOfflineReceiptSnapshot(record.receiptSnapshotJson);
  if (snapshot.isEmpty) return null;

  final storeName = snapshot['store_name'];
  final paymentMethod = snapshot['payment_method'];
  final totalAmount = snapshot['total_amount'];
  final paidAmount = snapshot['paid_amount'];
  final changeAmount = snapshot['change_amount'];
  final rawItems = snapshot['items'];
  if (storeName is! String ||
      storeName.trim().isEmpty ||
      paymentMethod is! String ||
      paymentMethod.trim().isEmpty ||
      totalAmount is! num ||
      !totalAmount.isFinite ||
      paidAmount is! num ||
      !paidAmount.isFinite ||
      changeAmount is! num ||
      !changeAmount.isFinite ||
      rawItems is! List ||
      rawItems.isEmpty) {
    return null;
  }

  const optionalStringFields = [
    'address',
    'logo_url',
    'outlet_name',
    'cashier_name',
    'member_name',
    'table_number',
    'notes',
  ];
  if (optionalStringFields.any(
    (key) =>
        snapshot.containsKey(key) &&
        snapshot[key] != null &&
        snapshot[key] is! String,
  )) {
    return null;
  }
  const optionalAmountFields = [
    'subtotal',
    'tax_amount',
    'service_charge',
    'discount_amount',
  ];
  if (optionalAmountFields.any((key) {
    final value = snapshot[key];
    return value != null && (value is! num || !value.isFinite);
  })) {
    return null;
  }

  final items = <TransactionReceiptItem>[];
  for (final rawItem in rawItems) {
    if (rawItem is! Map<String, dynamic>) return null;
    final productName = rawItem['product_name'];
    final quantity = rawItem['quantity'];
    final unitPrice = rawItem['unit_price'];
    final rawVariants = rawItem['selected_variants'];
    final notes = rawItem['notes'];
    if (productName is! String ||
        productName.trim().isEmpty ||
        quantity is! int ||
        quantity <= 0 ||
        unitPrice is! num ||
        !unitPrice.isFinite ||
        (rawVariants != null && rawVariants is! List) ||
        (notes != null && notes is! String)) {
      return null;
    }

    final variants = <TransactionReceiptVariant>[];
    if (rawVariants is List) {
      for (final rawVariant in rawVariants) {
        if (rawVariant is! Map<String, dynamic>) return null;
        final groupName = rawVariant['group_name'];
        final optionName = rawVariant['option_name'];
        if (groupName is! String ||
            groupName.trim().isEmpty ||
            optionName is! String ||
            optionName.trim().isEmpty) {
          return null;
        }
        variants.add(
          TransactionReceiptVariant(
            groupName: groupName,
            optionName: optionName,
          ),
        );
      }
    }
    items.add(
      TransactionReceiptItem(
        productName: productName,
        quantity: quantity,
        price: unitPrice,
        notes: notes is String ? notes : '',
        variants: variants,
      ),
    );
  }

  String optionalString(String key) =>
      snapshot[key] is String ? snapshot[key] as String : '';
  num? optionalAmount(String key) =>
      snapshot[key] is num ? snapshot[key] as num : null;

  final outletName = optionalString('outlet_name');
  return TransactionReceiptData(
    transactionId: record.localId,
    status: record.status,
    storeName: storeName,
    outletName: outletName.isEmpty ? record.outletId : outletName,
    address: optionalString('address'),
    logoUrl: optionalString('logo_url'),
    createdAt: record.createdAtLocal,
    cashierName: optionalString('cashier_name'),
    memberName: optionalString('member_name'),
    tableNumber: optionalString('table_number'),
    items: items,
    subtotal: optionalAmount('subtotal'),
    taxAmount: optionalAmount('tax_amount'),
    serviceCharge: optionalAmount('service_charge'),
    discountAmount: optionalAmount('discount_amount'),
    totalAmount: totalAmount,
    paymentMethod: paymentMethod,
    paidAmount: paidAmount,
    changeAmount: changeAmount,
    notes: optionalString('notes'),
    isOffline: record.status != 'synced',
    isOpenBill: record.transactionType == 'open_bill',
    isReconciliation: record.status == 'needs_reconciliation',
  );
}
