import '../../domain/entities/balance.dart';
import '../../domain/repositories/balances_repository.dart';
import '../datasources/balances_remote_data_source.dart';

class BalancesRepositoryImpl implements BalancesRepository {
  const BalancesRepositoryImpl(this._remoteDataSource);

  final BalancesRemoteDataSource _remoteDataSource;

  @override
  Future<List<BalanceAccount>> getBalances() =>
      _remoteDataSource.getBalances();

  @override
  Future<List<BalanceHistoryEntry>> getHistory() =>
      _remoteDataSource.getHistory();

  @override
  Future<void> recordExpense({
    required String paymentMethod,
    required num amount,
    required String notes,
  }) => _remoteDataSource.recordExpense(
    paymentMethod: paymentMethod,
    amount: amount,
    notes: notes,
  );

  @override
  Future<void> adjustBalance({
    required String paymentMethod,
    required num actualBalance,
    required String notes,
  }) => _remoteDataSource.adjustBalance(
    paymentMethod: paymentMethod,
    actualBalance: actualBalance,
    notes: notes,
  );
}
