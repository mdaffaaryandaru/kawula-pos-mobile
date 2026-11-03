// Project imports:
import 'package:kawula_pos/features/products/data/datasources/catalog_remote_data_source.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._remoteDataSource);

  final CatalogRemoteDataSource _remoteDataSource;

  @override
  Future<List<ProductCategory>> getCategories() {
    return _remoteDataSource.getCategories();
  }

  @override
  Future<List<CatalogProduct>> getProducts() {
    return _remoteDataSource.getProducts();
  }
}
