import '../../domain/entities/payment_method.dart';

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.name,
    required super.code,
    required super.description,
    required super.isActive,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final code = json['code'];
    final description = json['description'];
    if (id is! String || name is! String || code is! String) {
      throw const FormatException(
        'Data metode pembayaran dari server tidak valid.',
      );
    }
    return PaymentMethodModel(
      id: id,
      name: name,
      code: code,
      description: description is String ? description : '',
      isActive: json['is_active'] != false,
    );
  }
}
