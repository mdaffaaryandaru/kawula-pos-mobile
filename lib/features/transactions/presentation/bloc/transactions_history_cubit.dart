import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';

sealed class TransactionsHistoryState {
  const TransactionsHistoryState();
}

final class TransactionsHistoryLoading extends TransactionsHistoryState {
  const TransactionsHistoryLoading();
}

final class TransactionsHistoryLoaded extends TransactionsHistoryState {
  const TransactionsHistoryLoaded(this.transactions, {this.errorMessage});

  final List<TransactionRecord> transactions;
  final String? errorMessage;
}

final class TransactionsHistoryFailure extends TransactionsHistoryState {
  const TransactionsHistoryFailure(this.message);

  final String message;
}

class TransactionsHistoryCubit extends Cubit<TransactionsHistoryState> {
  TransactionsHistoryCubit(this._repository)
    : super(const TransactionsHistoryLoading());

  final CheckoutRepository _repository;

  Future<void> load() async {
    emit(const TransactionsHistoryLoading());
    try {
      final transactions = await _repository.getTransactions();
      emit(TransactionsHistoryLoaded(transactions));
    } catch (error) {
      emit(TransactionsHistoryFailure(_messageFor(error)));
    }
  }

  Future<void> settle({
    required TransactionRecord transaction,
    required String paymentMethod,
    required num paidAmount,
    required String pin,
  }) async {
    final currentState = state;
    if (currentState is! TransactionsHistoryLoaded) return;
    try {
      await _repository.payPendingTransaction(
        transactionId: transaction.id,
        paymentMethod: paymentMethod,
        paidAmount: paidAmount,
        pin: pin,
      );
      await load();
    } catch (error) {
      emit(
        TransactionsHistoryLoaded(
          currentState.transactions,
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
