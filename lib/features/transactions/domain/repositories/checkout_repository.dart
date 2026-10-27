import '../../../products/presentation/bloc/cart_cubit.dart';
import '../entities/checkout.dart';

abstract interface class CheckoutRepository {
  Future<List<CheckoutPaymentMethod>> getPaymentMethods();

  Future<CheckoutSettings> getSettings();

  Future<List<TransactionRecord>> getTransactions();

  Future<CheckoutResult> payPendingTransaction({
    required String transactionId,
    required String paymentMethod,
    required num paidAmount,
    required String pin,
  });

  Future<CheckoutResult> createTransaction({
    required String outletId,
    required List<CartItem> items,
    required num estimatedTotal,
    required String paymentMethod,
    required num paidAmount,
    required String? pin,
    required bool openBill,
  });
}
