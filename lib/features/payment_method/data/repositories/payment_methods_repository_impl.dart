import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_methods_repository.dart';
import '../datasources/payment_methods_remote_data_source.dart';

class PaymentMethodsRepositoryImpl implements PaymentMethodsRepository {
  const PaymentMethodsRepositoryImpl(this._remoteDataSource);

  final PaymentMethodsRemoteDataSource _remoteDataSource;

  @override
  Future<List<PaymentMethod>> getPaymentMethods() =>
      _remoteDataSource.getPaymentMethods();

  @override
  Future<PaymentMethod> getPaymentMethod(String paymentMethodId) =>
      _remoteDataSource.getPaymentMethod(paymentMethodId);

  @override
  Future<PaymentMethod> savePaymentMethod({
    String? paymentMethodId,
    required String? code,
    required String name,
    required String description,
    required bool isActive,
  }) => _remoteDataSource.savePaymentMethod(
    paymentMethodId: paymentMethodId,
    code: code,
    name: name,
    description: description,
    isActive: isActive,
  );

  @override
  Future<void> deletePaymentMethod(String paymentMethodId) =>
      _remoteDataSource.deletePaymentMethod(paymentMethodId);
}
