import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/product_units/data/datasources/product_units_remote_data_source.dart';

void main() {
  test('loads product units from the product-units endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/product-units');
      expect(request.headers['Authorization']?.startsWith('Bearer '), isTrue);
      expect(request.headers['Authorization']?.endsWith('jwt-token'), isTrue);
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
    final dataSource = ProductUnitsRemoteDataSource(
      client,
      'http://localhost:3001/api/',
      () async => 'jwt-token',
    );

    final units = await dataSource.getProductUnits();

    expect(units.single.id, 'gram-id');
    expect(units.single.name, 'Gram');
    expect(units.single.abbreviation, 'g');
    expect(units.single.isActive, isTrue);
  });

  test('reports backend errors from product-units endpoint', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
    );
    final dataSource = ProductUnitsRemoteDataSource(
      client,
      'http://localhost:3001/api',
      () async => 'jwt-token',
    );

    await expectLater(
      dataSource.getProductUnits(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Unauthorized'),
        ),
      ),
    );
  });

  test('creates a product unit with the backend fields', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/product-units');
      expect(jsonDecode(request.body), {
        'name': 'Botol',
        'abbreviation': 'btl',
        'description': 'Satuan per botol',
        'is_active': true,
      });
      return http.Response(
        jsonEncode({
          '_id': 'bottle-id',
          'name': 'Botol',
          'abbreviation': 'btl',
          'description': 'Satuan per botol',
          'is_active': true,
        }),
        201,
      );
    });
    final source = ProductUnitsRemoteDataSource(
      client,
      'http://localhost:3001/api',
      () async => 'jwt-token',
    );

    final unit = await source.saveProductUnit(
      name: 'Botol',
      abbreviation: 'btl',
      description: 'Satuan per botol',
      isActive: true,
    );

    expect(unit.id, 'bottle-id');
    expect(unit.description, 'Satuan per botol');
  });

  test('updates an existing product unit', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/product-units/bottle-id');
      expect(jsonDecode(request.body), {
        'name': 'Botol Kaca',
        'abbreviation': 'btl',
        'description': 'Botol kaca',
        'is_active': false,
      });
      return http.Response(
        jsonEncode({
          '_id': 'bottle-id',
          'name': 'Botol Kaca',
          'abbreviation': 'btl',
          'description': 'Botol kaca',
          'is_active': false,
        }),
        200,
      );
    });
    final source = ProductUnitsRemoteDataSource(
      client,
      'http://localhost:3001/api',
      () async => 'jwt-token',
    );

    final unit = await source.saveProductUnit(
      unitId: 'bottle-id',
      name: 'Botol Kaca',
      abbreviation: 'btl',
      description: 'Botol kaca',
      isActive: false,
    );

    expect(unit.isActive, isFalse);
  });

  test('deletes a product unit', () async {
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/product-units/bottle-id');
      return http.Response(
        jsonEncode({'message': 'Satuan produk berhasil dihapus'}),
        200,
      );
    });
    final source = ProductUnitsRemoteDataSource(
      client,
      'http://localhost:3001/api',
      () async => 'jwt-token',
    );

    await source.deleteProductUnit('bottle-id');
  });
}
