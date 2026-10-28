import '../../../products/presentation/bloc/cart_cubit.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_remote_data_source.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  const CheckoutRepositoryImpl(this._remoteDataSource);

  final CheckoutRemoteDataSource _remoteDataSource;

  @override
  Future<List<CheckoutPaymentMethod>> getPaymentMethods() {
    return _remoteDataSource.getPaymentMethods();
  }

  @override
  Future<CheckoutSettings> getSettings() => _remoteDataSource.getSettings();

  @override
  Future<List<TransactionRecord>> getTransactions() {
    return _remoteDataSource.getTransactions();
  }

  @override
  Future<List<Member>> searchMembers(String search) =>
      _remoteDataSource.searchMembers(search);

  @override
  Future<CheckoutResult> payPendingTransaction({
    required String transactionId,
    required String paymentMethod,
    required num paidAmount,
    required String pin,
  }) {
    return _remoteDataSource.payPendingTransaction(
      transactionId: transactionId,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      pin: pin,
    );
  }

  @override
  Future<CheckoutResult> createTransaction({
    required String outletId,
    required List<CartItem> items,
    required num estimatedTotal,
    required String paymentMethod,
    required num paidAmount,
    required String? pin,
    required bool openBill,
    String? memberId,
  }) {
    return _remoteDataSource.createTransaction(
      outletId: outletId,
      items: items,
      estimatedTotal: estimatedTotal,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      pin: pin,
      openBill: openBill,
      memberId: memberId,
    );
  }
}
