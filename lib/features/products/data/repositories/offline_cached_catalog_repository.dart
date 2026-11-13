import 'dart:convert';

import 'package:kawula_pos/features/products/data/models/catalog_models.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/offline/data/cache/offline_master_data_cache.dart';
import 'package:kawula_pos/features/offline/data/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/features/offline/data/cache/run_with_network_cache.dart';

class OfflineCachedCatalogRepository implements CatalogRepository {
  const OfflineCachedCatalogRepository(
    this._delegate,
    this._cache, {
    this.offlineTransactionsDao,
  });

  final CatalogRepository _delegate;
  final OfflineMasterDataCache _cache;
  final OfflineTransactionsDao? offlineTransactionsDao;

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
      return _applyOfflineStockEstimate(products);
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
      final products = decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Data produk pada cache katalog tidak valid.',
              );
            }
            return CatalogProductModel.fromJson(item);
          })
          .toList(growable: false);
      return _applyOfflineStockEstimate(products);
    },
    skipRequest: _cache.shouldUseOfflineData,
    onNetworkFailure: _cache.markOffline,
    onRequestSuccess: _cache.markOnline,
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
    skipRequest: _cache.shouldUseOfflineData,
    onNetworkFailure: _cache.markOffline,
    onRequestSuccess: _cache.markOnline,
  );

  Future<List<CatalogProduct>> _applyOfflineStockEstimate(
    List<CatalogProduct> products,
  ) async {
    final dao = offlineTransactionsDao;
    final ownerUserId = _cache.userId;
    final outletId = _cache.outletId;
    if (dao == null || ownerUserId == null || outletId == null) {
      return products;
    }

    final unresolvedSales = await dao.getUnresolvedSales(
      ownerUserId: ownerUserId,
      outletId: outletId,
    );
    if (unresolvedSales.isEmpty) return products;

    final soldQuantities = <String, int>{};
    for (final transaction in unresolvedSales) {
      final payload = jsonDecode(transaction.payloadJson);
      if (payload is! Map<String, dynamic> || payload['items'] is! List) {
        continue;
      }
      for (final item in payload['items'] as List) {
        if (item is! Map<String, dynamic>) continue;
        final productId = item['product_id'];
        final quantity = item['quantity'];
        if (productId is! String || quantity is! num || quantity <= 0) {
          continue;
        }
        soldQuantities.update(
          productId,
          (existing) => existing + quantity.toInt(),
          ifAbsent: () => quantity.toInt(),
        );
      }
    }

    return products
        .map((product) {
          final stock = product.stock;
          final sold = soldQuantities[product.id];
          if (stock == null || sold == null) return product;
          return CatalogProductModel(
            id: product.id,
            name: product.name,
            price: product.price,
            imageUrl: product.imageUrl,
            isActive: product.isActive,
            category: product.category,
            variantGroups: product.variantGroups,
            images: product.images,
            stock: (stock - sold).clamp(0, double.infinity),
            discount: product.discount,
            discountId: product.discountId,
          );
        })
        .toList(growable: false);
  }
}
