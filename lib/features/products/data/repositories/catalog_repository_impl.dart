import '../../domain/entities/catalog_product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_data_source.dart';

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
