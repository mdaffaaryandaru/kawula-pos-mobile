import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/inventories/data/datasources/inventory_remote_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test('loads inventory items including their base units', () async {
    final client = MockClient((request) async {
      expect(request.headers['Authorization']?.startsWith('Bearer '), isTrue);
      expect(request.headers['Authorization']?.endsWith('jwt-token'), isTrue);
      expect(request.method, 'GET');
      expect(request.url.path, '/api/inventories');
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
    });
    final dataSource = InventoryRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final inventories = await dataSource.getInventories();

    expect(inventories.single.id, 'inventory-id');
    expect(inventories.single.unit.abbreviation, 'g');
    expect(inventories.single.unit.id, 'gram-id');
  });

  test('creates an inventory item with the backend payload fields', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/inventories');
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload, {
        'name': 'Susu',
        'stock': 3,
        'unit_id': 'liter-id',
        'category': 'Dairy',
        'description': 'Susu segar',
        'buy_price': 18000,
        'min_stock': 1,
        'max_stock': 10,
        'is_active': true,
      });
      return http.Response('{}', 201);
    });
    final source = InventoryRemoteDataSource(
      client,
      baseUrl,
      () async => 'token',
    );

    await source.saveInventory(
      name: 'Susu',
      stock: 3,
      unitId: 'liter-id',
      category: 'Dairy',
      description: 'Susu segar',
      buyPrice: 18000,
      minStock: 1,
      maxStock: 10,
      isActive: true,
    );
  });

  test('updates inventory without overwriting its current stock', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/inventories/item-id');
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['name'], 'Susu UHT');
      expect(payload.containsKey('stock'), isFalse);
      return http.Response('{}', 200);
    });
    final source = InventoryRemoteDataSource(
      client,
      baseUrl,
      () async => 'token',
    );

    await source.saveInventory(
      inventoryId: 'item-id',
      name: 'Susu UHT',
      stock: null,
      unitId: 'liter-id',
      category: '',
      description: '',
      buyPrice: 18000,
      minStock: 1,
      maxStock: null,
      isActive: true,
    );
  });

  test('adjusts stock and requests the corresponding endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/inventories/item-id/adjust');
      expect(jsonDecode(request.body), {
        'type': 'out',
        'quantity': 0.5,
        'notes': 'Rusak',
      });
      return http.Response('{}', 200);
    });
    final source = InventoryRemoteDataSource(
      client,
      baseUrl,
      () async => 'token',
    );

    await source.adjustStock(
      inventoryId: 'item-id',
      type: 'out',
      quantity: 0.5,
      notes: 'Rusak',
    );
  });

  test('deletes inventory through the backend endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/inventories/item-id');
      return http.Response('{"message":"deleted"}', 200);
    });
    final source = InventoryRemoteDataSource(
      client,
      baseUrl,
      () async => 'token',
    );

    await source.deleteInventory('item-id');
  });

  test('parses inventory mutation history', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/inventories/item-id/mutations');
      return http.Response(
        jsonEncode([
          {
            '_id': 'mutation-id',
            'type': 'in',
            'quantity': 4,
            'current_stock': 15,
            'notes': 'Pembelian',
            'createdAt': '2025-01-02T03:04:00.000Z',
            'created_by': {'name': 'Admin'},
          },
        ]),
        200,
      );
    });
    final source = InventoryRemoteDataSource(
      client,
      baseUrl,
      () async => 'token',
    );

    final history = await source.getMutations('item-id');

    expect(history.single.id, 'mutation-id');
    expect(history.single.currentStock, 15);
    expect(history.single.createdBy, 'Admin');
    expect(
      history.single.createdAt,
      DateTime.parse('2025-01-02T03:04:00.000Z'),
    );
  });
}
