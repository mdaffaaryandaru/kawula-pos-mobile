import 'package:image_picker/image_picker.dart';

import '../../../categories/domain/entities/managed_category.dart';
import '../../../categories/domain/repositories/categories_repository.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../../../inventories/domain/entities/inventory_item.dart';
import '../../../inventories/domain/repositories/inventory_repository.dart';
import '../../../variant_groups/domain/repositories/variant_groups_repository.dart';
import '../../domain/entities/product_management.dart';
import '../../domain/repositories/product_management_repository.dart';
import '../datasources/product_management_remote_data_source.dart';

class ProductManagementRepositoryImpl implements ProductManagementRepository {
  const ProductManagementRepositoryImpl(
    this._remoteDataSource,
    this._categoriesRepository,
    this._variantGroupsRepository,
    this._inventoryRepository,
  );

  final ProductManagementRemoteDataSource _remoteDataSource;
  final CategoriesRepository _categoriesRepository;
  final VariantGroupsRepository _variantGroupsRepository;
  final InventoryRepository _inventoryRepository;

  @override
  Future<List<ManagedProduct>> getProducts() => _remoteDataSource.getProducts();

  @override
  Future<List<ManagedCategory>> getCategories() =>
      _categoriesRepository.getCategories();

  @override
  Future<List<ManagedVariantGroup>> getVariantGroups() async {
    final definitions = await _variantGroupsRepository
        .getVariantGroupDefinitions();
    return definitions
        .map(
          (group) => ManagedVariantGroup(
            id: group.id,
            name: group.name,
            group: ProductVariantGroup(
              name: group.name,
              isRequired: group.isRequired,
              minSelection: group.minSelection,
              maxSelection: group.maxSelection,
              options: group.options
                  .map(
                    (option) => ProductVariantOption(
                      name: option.name,
                      priceAdjustment: option.priceAdjustment,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<InventoryItem>> getInventories() =>
      _inventoryRepository.getInventories();

  @override
  Future<List<ProductUnit>> getProductUnits() =>
      _inventoryRepository.getProductUnits();

  @override
  Future<List<String>> uploadProductImages(List<XFile> images) =>
      _remoteDataSource.uploadProductImages(images);

  @override
  Future<ManagedProduct> saveProduct({
    String? productId,
    required String name,
    required num price,
    required num stock,
    required String categoryId,
    required List<String> variantGroupIds,
    required List<ProductImage> images,
    required bool isActive,
  }) {
    return _remoteDataSource.saveProduct(
      productId: productId,
      name: name,
      price: price,
      stock: stock,
      categoryId: categoryId,
      variantGroupIds: variantGroupIds,
      images: images,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteProduct(String productId) =>
      _remoteDataSource.deleteProduct(productId);

  @override
  Future<void> addRecipe({
    required String productId,
    required String inventoryId,
    required num quantity,
    required String unitId,
    required num conversionFactor,
  }) => _remoteDataSource.addRecipe(
    productId: productId,
    inventoryId: inventoryId,
    quantity: quantity,
    unitId: unitId,
    conversionFactor: conversionFactor,
  );

  @override
  Future<void> removeRecipe({
    required String productId,
    required int recipeIndex,
  }) => _remoteDataSource.removeRecipe(
    productId: productId,
    recipeIndex: recipeIndex,
  );
}
