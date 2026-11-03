// Project imports:
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';

abstract interface class CatalogRepository {
  Future<List<CatalogProduct>> getProducts();

  Future<List<ProductCategory>> getCategories();
}
