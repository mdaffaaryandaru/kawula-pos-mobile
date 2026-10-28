import '../entities/inventory_item.dart';

abstract interface class InventoryRepository {
  Future<List<InventoryItem>> getInventories();

  Future<List<ProductUnit>> getProductUnits();
}
