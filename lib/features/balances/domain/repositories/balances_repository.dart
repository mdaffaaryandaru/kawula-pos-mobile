import '../entities/balance.dart';

abstract interface class BalancesRepository {
  Future<List<BalanceAccount>> getBalances();

  Future<List<BalanceHistoryEntry>> getHistory();

  Future<void> recordExpense({
    required String paymentMethod,
    required num amount,
    required String notes,
  });

  Future<void> adjustBalance({
    required String paymentMethod,
    required num actualBalance,
    required String notes,
  });
}
