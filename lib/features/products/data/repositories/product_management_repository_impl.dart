import 'package:image_picker/image_picker.dart';

import '../../../categories/domain/entities/managed_category.dart';
import '../../../categories/domain/repositories/categories_repository.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../../domain/entities/product_management.dart';
import '../../domain/repositories/product_management_repository.dart';
import '../datasources/product_management_remote_data_source.dart';

class ProductManagementRepositoryImpl implements ProductManagementRepository {
  const ProductManagementRepositoryImpl(
    this._remoteDataSource,
    this._categoriesRepository,
  );

  final ProductManagementRemoteDataSource _remoteDataSource;
  final CategoriesRepository _categoriesRepository;

  @override
  Future<List<ManagedProduct>> getProducts() => _remoteDataSource.getProducts();

  @override
  Future<List<ManagedCategory>> getCategories() =>
      _categoriesRepository.getCategories();

  @override
  Future<List<ManagedVariantGroup>> getVariantGroups() =>
      _remoteDataSource.getVariantGroups();

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
}
