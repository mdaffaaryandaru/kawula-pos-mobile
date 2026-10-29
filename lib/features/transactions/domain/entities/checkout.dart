class CheckoutPaymentMethod {
  const CheckoutPaymentMethod({required this.name, required this.code});

  final String name;
  final String code;

  bool get isCash => code.toUpperCase() == 'CASH';
  bool get isOpenBill => code.toUpperCase() == 'OPEN_BILL';
}

class CheckoutSettings {
  const CheckoutSettings({
    required this.taxPercentage,
    required this.serviceCharge,
    this.storeName = '',
    this.address = '',
    this.logoUrl = '',
  });

  final num taxPercentage;
  final num serviceCharge;
  final String storeName;
  final String address;
  final String logoUrl;
}

class CheckoutResult {
  const CheckoutResult({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paidAmount,
    required this.changeAmount,
    required this.createdAt,
    this.subtotal,
    this.taxAmount,
    this.serviceCharge,
    this.discountAmount,
    this.items = const [],
    this.notes = '',
    this.tableNumber = '',
    this.memberName = '',
  });

  final String id;
  final String status;
  final num totalAmount;
  final String paymentMethod;
  final num paidAmount;
  final num changeAmount;
  final DateTime? createdAt;
  final num? subtotal;
  final num? taxAmount;
  final num? serviceCharge;
  final num? discountAmount;
  final List<CheckoutResultItem> items;
  final String notes;
  final String tableNumber;
  final String memberName;
}

class CheckoutResultItem {
  const CheckoutResultItem({
    required this.productName,
    required this.quantity,
    required this.price,
    this.selectedVariants = const [],
    this.notes = '',
  });

  final String productName;
  final int quantity;
  final num price;
  final List<CheckoutResultVariant> selectedVariants;
  final String notes;
}

class CheckoutResultVariant {
  const CheckoutResultVariant({
    required this.groupName,
    required this.optionName,
  });

  final String groupName;
  final String optionName;
}

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paidAmount,
    required this.changeAmount,
    required this.createdAt,
    required this.items,
    this.notes = '',
    this.subtotal = 0,
    this.taxAmount = 0,
    this.serviceCharge = 0,
    this.discountAmount = 0,
    this.cogs = 0,
    this.refundAmount = 0,
    this.outletName = '',
    this.cashierName = '',
    this.memberName = '',
    this.tableNumber = '',
    this.refundReason = '',
    this.refundedAt,
  });

  final String id;
  final String status;
  final num totalAmount;
  final String paymentMethod;
  final num paidAmount;
  final num changeAmount;
  final DateTime? createdAt;
  final List<TransactionRecordItem> items;
  final String notes;
  final num subtotal;
  final num taxAmount;
  final num serviceCharge;
  final num discountAmount;
  final num cogs;
  final num refundAmount;
  final String outletName;
  final String cashierName;
  final String memberName;
  final String tableNumber;
  final String refundReason;
  final DateTime? refundedAt;

  bool get isPending => status.toLowerCase() == 'pending';

  TransactionRecord withFallbackDetails(TransactionRecord fallback) =>
      TransactionRecord(
        id: id,
        status: status,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        changeAmount: changeAmount,
        createdAt: createdAt,
        items: items,
        notes: notes,
        subtotal: subtotal,
        taxAmount: taxAmount,
        serviceCharge: serviceCharge,
        discountAmount: discountAmount,
        cogs: cogs,
        refundAmount: refundAmount,
        outletName: outletName.isEmpty ? fallback.outletName : outletName,
        cashierName: cashierName.isEmpty ? fallback.cashierName : cashierName,
        memberName: memberName.isEmpty ? fallback.memberName : memberName,
        tableNumber: tableNumber.isEmpty ? fallback.tableNumber : tableNumber,
        refundReason: refundReason.isEmpty
            ? fallback.refundReason
            : refundReason,
        refundedAt: refundedAt ?? fallback.refundedAt,
      );
}

class TransactionRecordItem {
  const TransactionRecordItem({
    required this.productName,
    required this.quantity,
    required this.price,
    this.notes = '',
    this.selectedVariants = const [],
  });

  final String productName;
  final int quantity;
  final num price;
  final String notes;
  final List<CheckoutResultVariant> selectedVariants;
}
