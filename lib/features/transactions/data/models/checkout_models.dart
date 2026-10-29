import '../../domain/entities/checkout.dart';

class CheckoutPaymentMethodModel extends CheckoutPaymentMethod {
  const CheckoutPaymentMethodModel({required super.name, required super.code});

  factory CheckoutPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final code = json['code'];
    if (name is! String || code is! String) {
      throw const FormatException('Data metode pembayaran tidak valid.');
    }
    return CheckoutPaymentMethodModel(name: name, code: code);
  }
}

class CheckoutSettingsModel extends CheckoutSettings {
  const CheckoutSettingsModel({
    required super.taxPercentage,
    required super.serviceCharge,
    super.storeName,
    super.address,
    super.logoUrl,
  });

  factory CheckoutSettingsModel.fromJson(Map<String, dynamic> json) {
    final tax = json['tax_percentage'] ?? 0;
    final service = json['service_charge'] ?? 0;
    if (tax is! num || service is! num) {
      throw const FormatException('Pengaturan pajak toko tidak valid.');
    }
    return CheckoutSettingsModel(
      taxPercentage: tax,
      serviceCharge: service,
      storeName: json['store_name'] is String
          ? json['store_name'] as String
          : '',
      address: json['address'] is String ? json['address'] as String : '',
      logoUrl: json['logo_url'] is String ? json['logo_url'] as String : '',
    );
  }
}

class CheckoutResultModel extends CheckoutResult {
  const CheckoutResultModel({
    required super.id,
    required super.status,
    required super.totalAmount,
    required super.paymentMethod,
    required super.paidAmount,
    required super.changeAmount,
    required super.createdAt,
    super.subtotal,
    super.taxAmount,
    super.serviceCharge,
    super.discountAmount,
    super.items,
    super.notes,
    super.tableNumber,
    super.memberName,
  });

  factory CheckoutResultModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final status = json['status'];
    final total = json['total_amount'];
    final method = json['payment_method'];
    final paid = json['paid_amount'] ?? 0;
    final change = json['change_amount'] ?? 0;
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    final itemsJson = json['items'];
    if (id is! String ||
        status is! String ||
        total is! num ||
        method is! String ||
        paid is! num ||
        change is! num) {
      throw const FormatException('Respons transaksi tidak lengkap.');
    }
    if (itemsJson != null && itemsJson is! List) {
      throw const FormatException('Daftar item transaksi tidak valid.');
    }
    return CheckoutResultModel(
      id: id,
      status: status,
      totalAmount: total,
      paymentMethod: method,
      paidAmount: paid,
      changeAmount: change,
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue)
          : null,
      subtotal: json['subtotal'] is num ? json['subtotal'] as num : null,
      taxAmount: json['tax_amount'] is num ? json['tax_amount'] as num : null,
      serviceCharge: json['service_charge'] is num
          ? json['service_charge'] as num
          : null,
      discountAmount: json['discount_amount'] is num
          ? json['discount_amount'] as num
          : null,
      items: itemsJson is List
          ? itemsJson
                .map((item) {
                  if (item is! Map<String, dynamic>) {
                    throw const FormatException(
                      'Data item transaksi tidak valid.',
                    );
                  }
                  return CheckoutResultItemModel.fromJson(item);
                })
                .toList(growable: false)
          : const [],
      notes: json['notes'] is String ? json['notes'] as String : '',
      tableNumber: json['table_number'] is String
          ? json['table_number'] as String
          : '',
      memberName: _referenceField(json['member_id'], 'name'),
    );
  }
}

class CheckoutResultItemModel extends CheckoutResultItem {
  const CheckoutResultItemModel({
    required super.productName,
    required super.quantity,
    required super.price,
    super.selectedVariants,
    super.notes,
  });

  factory CheckoutResultItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product_id'];
    final productName = product is Map<String, dynamic>
        ? product['name']
        : product is String
        ? product
        : null;
    final quantity = json['quantity'];
    final price = json['price'];
    final variants = json['selected_variants'] ?? const [];
    if (productName is! String ||
        quantity is! num ||
        price is! num ||
        variants is! List) {
      throw const FormatException('Data item transaksi tidak lengkap.');
    }
    return CheckoutResultItemModel(
      productName: productName,
      quantity: quantity.toInt(),
      price: price,
      selectedVariants: variants
          .map((variant) {
            if (variant is! Map<String, dynamic> ||
                variant['group_name'] is! String ||
                variant['option_name'] is! String) {
              throw const FormatException('Data varian transaksi tidak valid.');
            }
            return CheckoutResultVariant(
              groupName: variant['group_name'] as String,
              optionName: variant['option_name'] as String,
            );
          })
          .toList(growable: false),
      notes: json['notes'] is String ? json['notes'] as String : '',
    );
  }
}

class TransactionRecordModel extends TransactionRecord {
  const TransactionRecordModel({
    required super.id,
    required super.status,
    required super.totalAmount,
    required super.paymentMethod,
    required super.paidAmount,
    required super.changeAmount,
    required super.createdAt,
    required super.items,
    super.notes,
    super.subtotal,
    super.taxAmount,
    super.serviceCharge,
    super.discountAmount,
    super.cogs,
    super.refundAmount,
    super.outletName,
    super.cashierName,
    super.memberName,
    super.tableNumber,
    super.refundReason,
    super.refundedAt,
  });

  factory TransactionRecordModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final status = json['status'];
    final total = json['total_amount'];
    final method = json['payment_method'] ?? '';
    final paid = json['paid_amount'] ?? 0;
    final change = json['change_amount'] ?? 0;
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    final itemsJson = json['items'];
    if (id is! String ||
        status is! String ||
        total is! num ||
        method is! String ||
        paid is! num ||
        change is! num ||
        itemsJson is! List) {
      throw const FormatException('Data transaksi tidak lengkap.');
    }

    return TransactionRecordModel(
      id: id,
      status: status,
      totalAmount: total,
      paymentMethod: method,
      paidAmount: paid,
      changeAmount: change,
      createdAt: createdAtValue is String
          ? DateTime.tryParse(createdAtValue)
          : null,
      subtotal: json['subtotal'] is num ? json['subtotal'] as num : 0,
      taxAmount: json['tax_amount'] is num ? json['tax_amount'] as num : 0,
      serviceCharge: json['service_charge'] is num
          ? json['service_charge'] as num
          : 0,
      discountAmount: json['discount_amount'] is num
          ? json['discount_amount'] as num
          : 0,
      cogs: json['cogs'] is num ? json['cogs'] as num : 0,
      refundAmount: json['refund_amount'] is num
          ? json['refund_amount'] as num
          : 0,
      outletName: _referenceField(json['outlet_id'], 'name'),
      cashierName: _referenceField(json['created_by'], 'name'),
      memberName: _referenceField(json['member_id'], 'name'),
      tableNumber: json['table_number'] is String
          ? json['table_number'] as String
          : '',
      refundReason: json['refund_reason'] is String
          ? json['refund_reason'] as String
          : '',
      refundedAt: (json['refunded_at'] ?? json['refundedAt']) is String
          ? DateTime.tryParse(
              (json['refunded_at'] ?? json['refundedAt']) as String,
            )
          : null,
      items: itemsJson
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Data item transaksi tidak valid.');
            }
            return TransactionRecordItemModel.fromJson(item);
          })
          .toList(growable: false),
      notes: json['notes'] is String ? json['notes'] as String : '',
    );
  }
}

String _referenceField(Object? value, String field) {
  if (value is Map<String, dynamic>) {
    final result = value[field];
    return result is String ? result : '';
  }
  return '';
}

class TransactionRecordItemModel extends TransactionRecordItem {
  const TransactionRecordItemModel({
    required super.productName,
    required super.quantity,
    required super.price,
    super.notes,
    super.selectedVariants,
  });

  factory TransactionRecordItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product_id'];
    final name = product is Map<String, dynamic>
        ? product['name']
        : product is String
        ? product
        : null;
    final quantity = json['quantity'];
    final price = json['price'];
    final variantsJson = json['selected_variants'] ?? const [];
    if (name is! String ||
        quantity is! num ||
        price is! num ||
        variantsJson is! List) {
      throw const FormatException('Data item transaksi tidak lengkap.');
    }
    return TransactionRecordItemModel(
      productName: name,
      quantity: quantity.toInt(),
      price: price,
      notes: json['notes'] is String ? json['notes'] as String : '',
      selectedVariants: variantsJson
          .map((variant) {
            if (variant is! Map<String, dynamic> ||
                variant['group_name'] is! String ||
                variant['option_name'] is! String) {
              throw const FormatException('Data varian transaksi tidak valid.');
            }
            return CheckoutResultVariant(
              groupName: variant['group_name'] as String,
              optionName: variant['option_name'] as String,
            );
          })
          .toList(growable: false),
    );
  }
}
