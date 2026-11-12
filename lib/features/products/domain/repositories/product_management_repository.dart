// Project imports:
import 'package:kawula_pos/features/categories/domain/entities/managed_category.dart';
import 'package:kawula_pos/features/inventories/domain/entities/inventory_item.dart';
import 'package:kawula_pos/features/product_units/domain/entities/product_unit.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/domain/entities/product_management.dart';
import 'package:kawula_pos/features/shared/domain/value_objects/image_upload_input.dart';

abstract interface class ProductManagementRepository {
  Future<List<ManagedProduct>> getProducts();

  Future<List<ManagedCategory>> getCategories();

  Future<List<ManagedVariantGroup>> getVariantGroups();

  Future<List<InventoryItem>> getInventories();

  Future<List<ProductUnit>> getProductUnits();

  Future<List<String>> uploadProductImages(List<ImageUploadInput> images);

  Future<ManagedProduct> saveProduct({
    String? productId,
    required String name,
    required num price,
    required num stock,
    required String categoryId,
    required List<String> variantGroupIds,
    required List<ProductImage> images,
    required bool isActive,
    String? discountId,
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
