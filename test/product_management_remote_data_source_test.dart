import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kawula_pos/features/products/data/datasources/product_management_remote_data_source.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test('loads products and their variant group references', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      if (request.url.path == '/api/products') {
        return http.Response(
          jsonEncode([
            {
              '_id': 'product-id',
              'name': 'Kopi',
              'price': 18000,
              'stock': 12,
              'image_url': '/uploads/products/kopi.jpg',
              'images': [
                {'url': '/uploads/products/kopi.jpg', 'is_main': true},
              ],
              'is_active': false,
              'category_id': {
                '_id': 'category-id',
                'name': 'Minuman',
                'is_active': true,
              },
              'discount_id': {
                '_id': 'discount-id',
                'type': 'percentage',
                'value': 10,
              },
              'variant_groups': ['group-id'],
            },
          ]),
          200,
        );
      }
      fail('Unexpected request: ${request.method} ${request.url}');
    });
    final dataSource = ProductManagementRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final products = await dataSource.getProducts();
    expect(products.single.product.name, 'Kopi');
    expect(products.single.product.isActive, isFalse);
    expect(products.single.product.stock, 12);
    expect(products.single.product.images.single.isMain, isTrue);
    expect(products.single.product.discountId, 'discount-id');
    expect(products.single.variantGroupIds, ['group-id']);
  });

  test('creates a product with supported fields and selected images', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('$baseUrl/products'));
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      expect(jsonDecode(request.body), {
        'name': 'Kopi',
        'price': 18000,
        'stock': 8,
        'image_url': '/uploads/products/kopi.jpg',
        'images': [
          {'url': '/uploads/products/kopi.jpg', 'is_main': true},
        ],
        'category_id': 'category-id',
        'variant_groups': ['group-id'],
        'is_active': true,
        'discount_id': null,
      });
      return http.Response(
        jsonEncode({
          '_id': 'product-id',
          'name': 'Kopi',
          'price': 18000,
          'stock': 8,
          'image_url': '/uploads/products/kopi.jpg',
          'images': [
            {'url': '/uploads/products/kopi.jpg', 'is_main': true},
          ],
          'is_active': true,
          'category_id': {
            '_id': 'category-id',
            'name': 'Minuman',
            'is_active': true,
          },
          'variant_groups': ['group-id'],
        }),
        201,
      );
    });
    final dataSource = ProductManagementRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final product = await dataSource.saveProduct(
      name: 'Kopi',
      price: 18000,
      stock: 8,
      categoryId: 'category-id',
      variantGroupIds: ['group-id'],
      images: const [
        ProductImage(url: '/uploads/products/kopi.jpg', isMain: true),
      ],
      isActive: true,
    );

    expect(product.product.id, 'product-id');
  });

  test('updates product stock, active status, and image gallery', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url, Uri.parse('$baseUrl/products/product-id'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['stock'], 3);
      expect(body['is_active'], false);
      expect(body['discount_id'], 'discount-id');
      expect(body['image_url'], '/uploads/products/kopi.jpg');
      expect(body['images'], [
        {'url': '/uploads/products/kopi.jpg', 'is_main': true},
      ]);
      return http.Response(
        jsonEncode({
          '_id': 'product-id',
          'name': 'Kopi',
          'price': 18000,
          'stock': 3,
          'image_url': '/uploads/products/kopi.jpg',
          'images': [
            {'url': '/uploads/products/kopi.jpg', 'is_main': true},
          ],
          'is_active': false,
          'category_id': {
            '_id': 'category-id',
            'name': 'Minuman',
            'is_active': true,
          },
          'discount_id': {
            '_id': 'discount-id',
            'type': 'percentage',
            'value': 10,
          },
          'variant_groups': [],
        }),
        200,
      );
    });
    final dataSource = ProductManagementRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final product = await dataSource.saveProduct(
      productId: 'product-id',
      name: 'Kopi',
      price: 18000,
      stock: 3,
      categoryId: 'category-id',
      variantGroupIds: const [],
      images: const [
        ProductImage(url: '/uploads/products/kopi.jpg', isMain: true),
      ],
      isActive: false,
      discountId: 'discount-id',
    );

    expect(product.product.stock, 3);
    expect(product.product.isActive, isFalse);
    expect(product.product.discountId, 'discount-id');
  });

  test('uploads pictures as multipart images with the bearer token', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('$baseUrl/products/upload'));
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      final multipartBody = request.body;
      expect(multipartBody, contains('name="images"'));
      expect(multipartBody, contains('filename="product.jpg"'));
      expect(multipartBody, contains('content-type: application/octet-stream'));
      return http.Response(
        jsonEncode({
          'urls': ['/uploads/products/product.jpg'],
          'count': 1,
        }),
        201,
      );
    });
    final dataSource = ProductManagementRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final urls = await dataSource.uploadProductImages([
      XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        mimeType: 'image/jpeg',
        path: 'product.jpg',
        name: 'product.jpg',
      ),
    ]);

    expect(urls, ['/uploads/products/product.jpg']);
  });

  test('deletes products through the existing endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      expect(request.url.path, '/api/products/product-id');
      return http.Response(jsonEncode({'message': 'Product deleted'}), 200);
    });
    final dataSource = ProductManagementRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    await dataSource.deleteProduct('product-id');
  });

  test('adds and removes recipes through the existing endpoints', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], isNotEmpty);
      if (request.method == 'POST') {
        expect(request.url, Uri.parse('$baseUrl/products/product-id/recipes'));
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), {
          'inventory_id': 'inventory-id',
          'quantity': 15,
          'unit_id': 'gram-id',
          'conversion_factor': 1,
        });
        requestCount++;
        return http.Response(jsonEncode({'message': 'Recipe added'}), 201);
      }
      expect(request.method, 'DELETE');
      expect(request.url, Uri.parse('$baseUrl/products/product-id/recipes/0'));
      requestCount++;
      return http.Response(jsonEncode({'message': 'Recipe deleted'}), 200);
    });
    final dataSource = ProductManagementRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    await dataSource.addRecipe(
      productId: 'product-id',
      inventoryId: 'inventory-id',
      quantity: 15,
      unitId: 'gram-id',
      conversionFactor: 1,
    );
    await dataSource.removeRecipe(productId: 'product-id', recipeIndex: 0);

    expect(requestCount, 2);
  });
}
