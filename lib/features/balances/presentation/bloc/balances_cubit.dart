import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/balance.dart';
import '../../domain/repositories/balances_repository.dart';

sealed class BalancesState {
  const BalancesState();
}

final class BalancesLoading extends BalancesState {
  const BalancesLoading();
}

final class BalancesLoaded extends BalancesState {
  const BalancesLoaded({
    required this.balances,
    required this.history,
    this.errorMessage,
  });

  final List<BalanceAccount> balances;
  final List<BalanceHistoryEntry> history;
  final String? errorMessage;
}

final class BalancesFailure extends BalancesState {
  const BalancesFailure(this.message);

  final String message;
}

class BalancesCubit extends Cubit<BalancesState> {
  BalancesCubit(this._repository) : super(const BalancesLoading());

  final BalancesRepository _repository;

  Future<void> load() async {
    emit(const BalancesLoading());
    try {
      final result = await Future.wait([
        _repository.getBalances(),
        _repository.getHistory(),
      ]);
      emit(
        BalancesLoaded(
          balances: result[0] as List<BalanceAccount>,
          history: result[1] as List<BalanceHistoryEntry>,
        ),
      );
    } catch (error) {
      emit(BalancesFailure(_messageFor(error)));
    }
  }

  Future<bool> recordExpense({
    required String paymentMethod,
    required num amount,
    required String notes,
  }) async {
    try {
      await _repository.recordExpense(
        paymentMethod: paymentMethod,
        amount: amount,
        notes: notes,
      );
      await load();
      return state is BalancesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> adjustBalance({
    required String paymentMethod,
    required num actualBalance,
    required String notes,
  }) async {
    try {
      await _repository.adjustBalance(
        paymentMethod: paymentMethod,
        actualBalance: actualBalance,
        notes: notes,
      );
      await load();
      return state is BalancesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is BalancesLoaded) {
      emit(
        BalancesLoaded(
          balances: currentState.balances,
          history: currentState.history,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(BalancesFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
