import '../entities/inventory_item.dart';

abstract interface class InventoryRepository {
  Future<List<InventoryItem>> getInventories();

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
  });

  Future<void> deleteInventory(String inventoryId);

  Future<void> adjustStock({
    required String inventoryId,
    required String type,
    required num quantity,
    required String notes,
  });

  Future<List<InventoryMutation>> getMutations(String inventoryId);
}
