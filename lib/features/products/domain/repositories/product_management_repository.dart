import 'package:image_picker/image_picker.dart';

import '../../../categories/domain/entities/managed_category.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../../../inventories/domain/entities/inventory_item.dart';
import '../entities/product_management.dart';

abstract interface class ProductManagementRepository {
  Future<List<ManagedProduct>> getProducts();

  Future<List<ManagedCategory>> getCategories();

  Future<List<ManagedVariantGroup>> getVariantGroups();

  Future<List<InventoryItem>> getInventories();

  Future<List<ProductUnit>> getProductUnits();

  Future<List<String>> uploadProductImages(List<XFile> images);

  Future<ManagedProduct> saveProduct({
    String? productId,
    required String name,
    required num price,
    required num stock,
    required String categoryId,
    required List<String> variantGroupIds,
    required List<ProductImage> images,
    required bool isActive,
  });

  Future<void> deleteProduct(String productId);

  Future<void> addRecipe({
    required String productId,
    required String inventoryId,
    required num quantity,
    required String unitId,
    required num conversionFactor,
  });

  Future<void> removeRecipe({
    required String productId,
    required int recipeIndex,
  });
}
