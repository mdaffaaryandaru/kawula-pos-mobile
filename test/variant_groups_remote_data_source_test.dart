import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/variant_groups/data/datasources/variant_groups_remote_data_source.dart';
import 'package:kawula_pos/features/variant_groups/domain/entities/variant_group_definition.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';
  const variantGroupResponse = {
    '_id': 'group-id',
    'name': 'Ukuran',
    'is_required': true,
    'min_selection': 1,
    'max_selection': 2,
    'options': [
      {
        'name': 'Large',
        'price_adjustment': 5000,
        'recipes': [
          {
            'inventory_id': {'_id': 'inventory-id', 'name': 'Susu'},
            'quantity': 30,
            'unit_id': {'_id': 'unit-id', 'name': 'Mililiter'},
            'conversion_factor': 1,
          },
        ],
      },
    ],
  };

  test(
    'manages variant groups and recipe fields using backend contract',
    () async {
      final requests = <String>[];
      final client = MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        if (request.url.path == '/api/inventories') {
          return http.Response(
            jsonEncode([
              {'_id': 'inventory-id', 'name': 'Susu', 'is_active': true},
            ]),
            200,
          );
        }
        if (request.url.path == '/api/product-units') {
          return http.Response(
            jsonEncode([
              {'_id': 'unit-id', 'name': 'Mililiter', 'is_active': true},
            ]),
            200,
          );
        }
        if (request.method == 'GET') {
          return http.Response(jsonEncode([variantGroupResponse]), 200);
        }
        if (request.method == 'DELETE') {
          return http.Response(jsonEncode({'message': 'deleted'}), 200);
        }

        expect(request.headers['Authorization'], isNotEmpty);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {
          'name': 'Ukuran',
          'is_required': true,
          'min_selection': 1,
          'max_selection': 2,
          'options': [
            {
              'name': 'Large',
              'price_adjustment': 5000,
              'recipes': [
                {
                  'inventory_id': 'inventory-id',
                  'quantity': 30,
                  'unit_id': 'unit-id',
                  'conversion_factor': 1,
                },
              ],
            },
          ],
        });
        return http.Response(jsonEncode(variantGroupResponse), 201);
      });
      final dataSource = VariantGroupsRemoteDataSource(
        client,
        baseUrl,
        () async => 'jwt-token',
      );
      const options = [
        VariantOptionDefinition(
          name: 'Large',
          priceAdjustment: 5000,
          recipes: [
            VariantRecipeDefinition(
              inventoryId: 'inventory-id',
              inventoryName: 'Susu',
              quantity: 30,
              unitId: 'unit-id',
              unitName: 'Mililiter',
              conversionFactor: 1,
            ),
          ],
        ),
      ];

      final groups = await dataSource.getVariantGroupDefinitions();
      final references = await dataSource.getVariantRecipeReferences();
      final saved = await dataSource.saveVariantGroup(
        name: 'Ukuran',
        isRequired: true,
        minSelection: 1,
        maxSelection: 2,
        options: options,
      );
      final updated = await dataSource.saveVariantGroup(
        groupId: 'group-id',
        name: 'Ukuran',
        isRequired: true,
        minSelection: 1,
        maxSelection: 2,
        options: options,
      );
      await dataSource.deleteVariantGroup('group-id');

      expect(groups.single.options.single.recipes.single.inventoryName, 'Susu');
      expect(references.inventories.single.name, 'Susu');
      expect(references.units.single.name, 'Mililiter');
      expect(saved.name, 'Ukuran');
      expect(updated.name, 'Ukuran');
      expect(requests, [
        'GET /api/variant-groups',
        'GET /api/inventories',
        'GET /api/product-units',
        'POST /api/variant-groups',
        'PATCH /api/variant-groups/group-id',
        'DELETE /api/variant-groups/group-id',
      ]);
    },
  );

  test('includes endpoint and status in request errors', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
    );
    final dataSource = VariantGroupsRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    await expectLater(
      dataSource.getVariantGroupDefinitions(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('GET /api/variant-groups: Unauthorized'),
        ),
      ),
    );
  });
}
