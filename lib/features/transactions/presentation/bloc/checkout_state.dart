import '../../domain/entities/checkout.dart';

sealed class CheckoutState {
  const CheckoutState();
}

final class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

final class CheckoutReady extends CheckoutState {
  const CheckoutReady({
    required this.paymentMethods,
    required this.settings,
    this.errorMessage,
  });

  final List<CheckoutPaymentMethod> paymentMethods;
  final CheckoutSettings settings;
  final String? errorMessage;
}

final class CheckoutSubmitting extends CheckoutState {
  const CheckoutSubmitting({
    required this.paymentMethods,
    required this.settings,
  });

  final List<CheckoutPaymentMethod> paymentMethods;
  final CheckoutSettings settings;
}

final class CheckoutCompleted extends CheckoutState {
  const CheckoutCompleted(this.result, this.settings);

  final CheckoutResult result;
  final CheckoutSettings settings;
}

final class CheckoutFailure extends CheckoutState {
  const CheckoutFailure(this.message);

  final String message;
}
