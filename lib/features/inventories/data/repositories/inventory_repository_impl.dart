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
  Future<void> saveInventory({
    String? inventoryId,
    required String name,
    required num? stock,
    required String unitId,
    required String category,
    required String description,
    required num buyPrice,
    required num minStock,
    required num? maxStock,
    required bool isActive,
  }) => _remoteDataSource.saveInventory(
    inventoryId: inventoryId,
    name: name,
    stock: stock,
    unitId: unitId,
    category: category,
    description: description,
    buyPrice: buyPrice,
    minStock: minStock,
    maxStock: maxStock,
    isActive: isActive,
  );

  @override
  Future<void> deleteInventory(String inventoryId) =>
      _remoteDataSource.deleteInventory(inventoryId);

  @override
  Future<void> adjustStock({
    required String inventoryId,
    required String type,
    required num quantity,
    required String notes,
  }) => _remoteDataSource.adjustStock(
    inventoryId: inventoryId,
    type: type,
    quantity: quantity,
    notes: notes,
  );

  @override
  Future<List<InventoryMutation>> getMutations(String inventoryId) =>
      _remoteDataSource.getMutations(inventoryId);
}
