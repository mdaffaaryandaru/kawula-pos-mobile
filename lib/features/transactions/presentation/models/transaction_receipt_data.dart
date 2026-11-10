// Project imports:
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';

class TransactionReceiptData {
  const TransactionReceiptData({
    required this.transactionId,
    required this.status,
    required this.storeName,
    required this.outletName,
    required this.address,
    required this.logoUrl,
    required this.createdAt,
    required this.cashierName,
    required this.memberName,
    required this.tableNumber,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceCharge,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paidAmount,
    required this.changeAmount,
    required this.notes,
    this.isOffline = false,
    this.isOpenBill = false,
    this.isReconciliation = false,
  });

  factory TransactionReceiptData.fromCheckout({
    required CheckoutResult result,
    required CheckoutSettings settings,
    String memberName = '',
    String tableNumber = '',
  }) => TransactionReceiptData(
    transactionId: result.id,
    status: result.status,
    storeName: settings.storeName.isEmpty ? 'Kawula' : settings.storeName,
    outletName: result.outletName,
    address: settings.address,
    logoUrl: settings.logoUrl,
    createdAt: result.createdAt,
    cashierName: result.cashierName,
    memberName: memberName.isEmpty ? result.memberName : memberName,
    tableNumber: result.tableNumber.isEmpty ? tableNumber : result.tableNumber,
    items: [
      for (final item in result.items)
        TransactionReceiptItem(
          productName: item.productName,
          quantity: item.quantity,
          price: item.price,
          notes: item.notes,
          variants: [
            for (final variant in item.selectedVariants)
              TransactionReceiptVariant(
                groupName: variant.groupName,
                optionName: variant.optionName,
              ),
          ],
        ),
    ],
    subtotal: result.subtotal,
    taxAmount: result.taxAmount,
    serviceCharge: result.serviceCharge,
    discountAmount: result.discountAmount,
    totalAmount: result.totalAmount,
    paymentMethod: result.paymentMethod,
    paidAmount: result.paidAmount,
    changeAmount: result.changeAmount,
    notes: result.notes,
    isOffline: result.isOffline,
    isOpenBill: result.isOpenBill,
    isReconciliation: result.status == 'needs_reconciliation',
  );

  factory TransactionReceiptData.fromTransaction(
    TransactionRecord record, {
    String logoUrl = '',
  }) => TransactionReceiptData(
    transactionId: record.id,
    status: record.status,
    storeName: record.outletName.isEmpty ? 'Kawula' : record.outletName,
    outletName: record.outletName,
    address: '',
    logoUrl: logoUrl,
    createdAt: record.createdAt,
    cashierName: record.cashierName,
    memberName: record.memberName,
    tableNumber: record.tableNumber,
    items: [
      for (final item in record.items)
        TransactionReceiptItem(
          productName: item.productName,
          quantity: item.quantity,
          price: item.price,
          notes: item.notes,
          variants: [
            for (final variant in item.selectedVariants)
              TransactionReceiptVariant(
                groupName: variant.groupName,
                optionName: variant.optionName,
              ),
          ],
        ),
    ],
    subtotal: record.subtotal,
    taxAmount: record.taxAmount,
    serviceCharge: record.serviceCharge,
    discountAmount: record.discountAmount,
    totalAmount: record.totalAmount,
    paymentMethod: record.paymentMethod,
    paidAmount: record.paidAmount,
    changeAmount: record.changeAmount,
    notes: record.notes,
    isOffline: record.id.startsWith('OFF-'),
    isOpenBill: record.status.toLowerCase() == 'offline_open_bill',
    isReconciliation:
        record.status.toLowerCase() == 'needs_reconciliation',
  );

  final String transactionId;
  final String status;
  final String storeName;
  final String outletName;
  final String address;
  final String logoUrl;
  final DateTime? createdAt;
  final String cashierName;
  final String memberName;
  final String tableNumber;
  final List<TransactionReceiptItem> items;
  final num? subtotal;
  final num? taxAmount;
  final num? serviceCharge;
  final num? discountAmount;
  final num totalAmount;
  final String paymentMethod;
  final num paidAmount;
  final num changeAmount;
  final String notes;
  final bool isOffline;
  final bool isOpenBill;
  final bool isReconciliation;

  bool get isPending =>
      isOpenBill || status.toLowerCase() == 'pending';
}

class TransactionReceiptItem {
  const TransactionReceiptItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.notes,
    required this.variants,
  });

  final String productName;
  final int quantity;
  final num price;
  final String notes;
  final List<TransactionReceiptVariant> variants;
}

class TransactionReceiptVariant {
  const TransactionReceiptVariant({
    required this.groupName,
    required this.optionName,
  });

  final String groupName;
  final String optionName;
}
