import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/inventories/data/datasources/inventory_remote_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test(
    'loads inventory items and product units from existing endpoints',
    () async {
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        if (request.url.path == '/api/inventories') {
          expect(request.method, 'GET');
          return http.Response(
            jsonEncode([
              {
                '_id': 'inventory-id',
                'name': 'Kopi',
                'stock': 1200,
                'unit_id': {
                  '_id': 'gram-id',
                  'name': 'Gram',
                  'abbreviation': 'g',
                  'is_active': true,
                },
                'is_active': true,
              },
            ]),
            200,
          );
        }
        expect(request.method, 'GET');
        expect(request.url.path, '/api/product-units');
        return http.Response(
          jsonEncode([
            {
              '_id': 'gram-id',
              'name': 'Gram',
              'abbreviation': 'g',
              'is_active': true,
            },
          ]),
          200,
        );
      });
      final dataSource = InventoryRemoteDataSource(
        client,
        baseUrl,
        () async => 'jwt-token',
      );

      final inventories = await dataSource.getInventories();
      final units = await dataSource.getProductUnits();

      expect(inventories.single.id, 'inventory-id');
      expect(inventories.single.unit.abbreviation, 'g');
      expect(units.single.id, 'gram-id');
    },
  );
}
