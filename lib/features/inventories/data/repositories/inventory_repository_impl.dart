import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._remoteDataSource);

  final InventoryRemoteDataSource _remoteDataSource;

  @override
  Future<List<InventoryItem>> getInventories() =>
      _remoteDataSource.getInventories();

  @override
  Future<List<ProductUnit>> getProductUnits() =>
      _remoteDataSource.getProductUnits();
}
