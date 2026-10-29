import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_methods_repository.dart';

sealed class PaymentMethodsState {
  const PaymentMethodsState();
}

final class PaymentMethodsLoading extends PaymentMethodsState {
  const PaymentMethodsLoading();
}

final class PaymentMethodsLoaded extends PaymentMethodsState {
  const PaymentMethodsLoaded({required this.paymentMethods, this.errorMessage});

  final List<PaymentMethod> paymentMethods;
  final String? errorMessage;
}

final class PaymentMethodsFailure extends PaymentMethodsState {
  const PaymentMethodsFailure(this.message);

  final String message;
}

class PaymentMethodsCubit extends Cubit<PaymentMethodsState> {
  PaymentMethodsCubit(this._repository) : super(const PaymentMethodsLoading());

  final PaymentMethodsRepository _repository;

  Future<void> load() async {
    emit(const PaymentMethodsLoading());
    try {
      emit(
        PaymentMethodsLoaded(
          paymentMethods: await _repository.getPaymentMethods(),
        ),
      );
    } catch (error) {
      emit(PaymentMethodsFailure(_messageFor(error)));
    }
  }

  Future<bool> save({
    String? paymentMethodId,
    required String? code,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    try {
      await _repository.savePaymentMethod(
        paymentMethodId: paymentMethodId,
        code: code,
        name: name,
        description: description,
        isActive: isActive,
      );
      await load();
      return state is PaymentMethodsLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> delete(String paymentMethodId) async {
    try {
      await _repository.deletePaymentMethod(paymentMethodId);
      await load();
      return state is PaymentMethodsLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is PaymentMethodsLoaded) {
      emit(
        PaymentMethodsLoaded(
          paymentMethods: currentState.paymentMethods,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(PaymentMethodsFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
