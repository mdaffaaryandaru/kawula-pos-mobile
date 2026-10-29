import '../entities/payment_method.dart';

abstract interface class PaymentMethodsRepository {
  Future<List<PaymentMethod>> getPaymentMethods();

  Future<PaymentMethod> getPaymentMethod(String paymentMethodId);

  Future<PaymentMethod> savePaymentMethod({
    String? paymentMethodId,
    required String? code,
    required String name,
    required String description,
    required bool isActive,
  });

  Future<void> deletePaymentMethod(String paymentMethodId);
}
