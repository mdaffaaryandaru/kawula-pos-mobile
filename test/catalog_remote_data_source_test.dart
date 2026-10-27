import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/products/data/datasources/catalog_remote_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test(
    'loads active products with category, discount, and variant data',
    () async {
      final client = MockClient((request) async {
        expect(request.url, Uri.parse('$baseUrl/products'));
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        return http.Response(
          jsonEncode([
            {
              '_id': 'product-id',
              'name': 'Kopi Susu',
              'price': 20000,
              'is_active': true,
              'image_url': '/uploads/products/coffee.jpg',
              'category_id': {
                '_id': 'category-id',
                'name': 'Minuman',
                'is_active': true,
              },
              'discount_id': {'type': 'percentage', 'value': 10},
              'variant_groups': [
                {
                  '_id': 'group-id',
                  'name': 'Ukuran',
                  'is_required': true,
                  'min_selection': 1,
                  'max_selection': 1,
                  'options': [
                    {
                      '_id': 'option-id',
                      'name': 'Besar',
                      'price_adjustment': 5000,
                    },
                  ],
                },
              ],
            },
            {
              '_id': 'inactive-product-id',
              'name': 'Produk Nonaktif',
              'price': 1000,
              'is_active': false,
            },
          ]),
          200,
        );
      });
      final dataSource = CatalogRemoteDataSource(
        client,
        baseUrl,
        () async => 'jwt-token',
      );

      final products = await dataSource.getProducts();

      expect(products, hasLength(1));
      expect(products.single.name, 'Kopi Susu');
      expect(products.single.category?.name, 'Minuman');
      expect(products.single.discountedPrice, 18000);
      expect(
        products.single.variantGroups.single.options.single.id,
        'option-id',
      );
    },
  );

  test('loads active categories and omits inactive categories', () async {
    final client = MockClient((request) async {
      expect(request.url, Uri.parse('$baseUrl/categories'));
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      return http.Response(
        jsonEncode([
          {'_id': 'active-id', 'name': 'Minuman', 'is_active': true},
          {'_id': 'inactive-id', 'name': 'Arsip', 'is_active': false},
        ]),
        200,
      );
    });
    final dataSource = CatalogRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final categories = await dataSource.getCategories();

    expect(categories, hasLength(1));
    expect(categories.single.name, 'Minuman');
  });
}
