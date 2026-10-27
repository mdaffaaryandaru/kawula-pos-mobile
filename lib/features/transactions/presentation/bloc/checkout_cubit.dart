import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../products/presentation/bloc/cart_cubit.dart';
import '../../domain/repositories/checkout_repository.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._repository) : super(const CheckoutLoading());

  final CheckoutRepository _repository;

  Future<void> load() async {
    emit(const CheckoutLoading());
    try {
      final methods = await _repository.getPaymentMethods();
      final settings = await _repository.getSettings();
      emit(CheckoutReady(paymentMethods: methods, settings: settings));
    } catch (error) {
      emit(CheckoutFailure(_messageFor(error)));
    }
  }

  Future<void> submit({
    required String outletId,
    required List<CartItem> items,
    required num estimatedTotal,
    required String paymentMethod,
    required num paidAmount,
    required String? pin,
    required bool openBill,
  }) async {
    final currentState = state;
    if (currentState is! CheckoutReady) return;
    if (items.isEmpty) {
      emit(
        CheckoutReady(
          paymentMethods: currentState.paymentMethods,
          settings: currentState.settings,
          errorMessage: 'Keranjang masih kosong.',
        ),
      );
      return;
    }

    emit(
      CheckoutSubmitting(
        paymentMethods: currentState.paymentMethods,
        settings: currentState.settings,
      ),
    );
    try {
      final result = await _repository.createTransaction(
        outletId: outletId,
        items: items,
        estimatedTotal: estimatedTotal,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        pin: pin,
        openBill: openBill,
      );
      emit(CheckoutCompleted(result, currentState.settings));
    } catch (error) {
      emit(
        CheckoutReady(
          paymentMethods: currentState.paymentMethods,
          settings: currentState.settings,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
