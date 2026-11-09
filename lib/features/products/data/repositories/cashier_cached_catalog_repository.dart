import 'dart:convert';

import 'package:kawula_pos/features/products/data/models/catalog_models.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/run_with_network_cache.dart';

class CashierCachedCatalogRepository implements CatalogRepository {
  const CashierCachedCatalogRepository(this._delegate, this._cache);

  final CatalogRepository _delegate;
  final CashierMasterDataCache _cache;

  @override
  Future<List<CatalogProduct>> getProducts() => runWithNetworkCache(
    request: () async {
      final products = await _delegate.getProducts();
      await _cache.save(
        cacheType: 'catalog_products',
        dataKey: 'all',
        payload: products
            .map((product) => CatalogProductModel.fromEntity(product).toJson())
            .toList(growable: false),
      );
      return products;
    },
    readCache: () async {
      final cached = await _cache.read(
        cacheType: 'catalog_products',
        dataKey: 'all',
      );
      if (cached == null) return null;
      final decoded = jsonDecode(jsonEncode(cached));
      if (decoded is! List) {
        throw const FormatException('Cache katalog produk tidak valid.');
      }
      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Data produk pada cache katalog tidak valid.',
              );
            }
            return CatalogProductModel.fromJson(item);
          })
          .toList(growable: false);
    },
  );

  @override
  Future<List<ProductCategory>> getCategories() => runWithNetworkCache(
    request: () async {
      final categories = await _delegate.getCategories();
      await _cache.save(
        cacheType: 'catalog_categories',
        dataKey: 'all',
        payload: categories
            .map(
              (category) => CatalogCategoryModel(
                id: category.id,
                name: category.name,
                isActive: category.isActive,
              ).toJson(),
            )
            .toList(growable: false),
      );
      return categories;
    },
    readCache: () async {
      final cached = await _cache.read(
        cacheType: 'catalog_categories',
        dataKey: 'all',
      );
      if (cached == null) return null;
      final decoded = jsonDecode(jsonEncode(cached));
      if (decoded is! List) {
        throw const FormatException('Cache kategori katalog tidak valid.');
      }
      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Data kategori pada cache katalog tidak valid.',
              );
            }
            return CatalogCategoryModel.fromJson(item);
          })
          .toList(growable: false);
    },
  );
}
