import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/categories/data/datasources/categories_remote_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test(
    'uses existing category list, create, update, and delete endpoints',
    () async {
      var deleteRequested = false;
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        if (request.method == 'GET') {
          expect(request.url, Uri.parse('$baseUrl/categories'));
          return http.Response(
            jsonEncode([
              {
                '_id': 'category-id',
                'name': 'Minuman',
                'description': 'Menu minuman',
                'is_active': true,
              },
            ]),
            200,
          );
        }
        if (request.method == 'POST') {
          expect(request.url, Uri.parse('$baseUrl/categories'));
          expect(jsonDecode(request.body), {
            'name': 'Makanan',
            'description': 'Menu makanan',
            'is_active': true,
          });
          return http.Response(
            jsonEncode({
              '_id': 'category-id',
              'name': 'Makanan',
              'description': 'Menu makanan',
              'is_active': true,
            }),
            201,
          );
        }
        if (request.method == 'PATCH') {
          expect(request.url, Uri.parse('$baseUrl/categories/category-id'));
          expect(jsonDecode(request.body), {
            'name': 'Makanan',
            'description': 'Menu baru',
            'is_active': false,
          });
          return http.Response(
            jsonEncode({
              '_id': 'category-id',
              'name': 'Makanan',
              'description': 'Menu baru',
              'is_active': false,
            }),
            200,
          );
        }
        expect(request.method, 'DELETE');
        expect(request.url, Uri.parse('$baseUrl/categories/category-id'));
        deleteRequested = true;
        return http.Response(jsonEncode({'message': 'Category deleted'}), 200);
      });
      final dataSource = CategoriesRemoteDataSource(
        client,
        baseUrl,
        () async => 'jwt-token',
      );

      final categories = await dataSource.getCategories();
      final created = await dataSource.saveCategory(
        name: 'Makanan',
        description: 'Menu makanan',
        isActive: true,
      );
      final updated = await dataSource.saveCategory(
        categoryId: 'category-id',
        name: 'Makanan',
        description: 'Menu baru',
        isActive: false,
      );
      await dataSource.deleteCategory('category-id');

      expect(categories.single.description, 'Menu minuman');
      expect(created.id, 'category-id');
      expect(updated.description, 'Menu baru');
      expect(updated.isActive, isFalse);
      expect(deleteRequested, isTrue);
    },
  );
}
