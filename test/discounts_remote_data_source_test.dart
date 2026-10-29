import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/discounts/data/datasources/discounts_remote_data_source.dart';
import 'package:kawula_pos/features/discounts/domain/entities/discount_definition.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test('uses existing discount list, create, update, and delete endpoints', () async {
    var deleteRequested = false;
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      if (request.method == 'GET') {
        expect(request.url, Uri.parse('$baseUrl/discounts'));
        return http.Response(jsonEncode([_discountJson()]), 200);
      }
      if (request.method == 'POST') {
        expect(request.url, Uri.parse('$baseUrl/discounts'));
        expect(jsonDecode(request.body), {
          'name': 'Happy Hour',
          'type': 'percentage',
          'value': 15,
          'description': 'Diskon sore',
          'is_active': true,
        });
        return http.Response(
          jsonEncode(_discountJson(name: 'Happy Hour', value: 15)),
          201,
        );
      }
      if (request.method == 'PATCH') {
        expect(request.url, Uri.parse('$baseUrl/discounts/discount-id'));
        expect(jsonDecode(request.body), {
          'name': 'Happy Hour',
          'type': 'nominal',
          'value': 10000,
          'description': 'Potongan sore',
          'is_active': false,
        });
        return http.Response(
          jsonEncode(
            _discountJson(
              name: 'Happy Hour',
              type: 'nominal',
              value: 10000,
              description: 'Potongan sore',
              isActive: false,
            ),
          ),
          200,
        );
      }
      expect(request.method, 'DELETE');
      expect(request.url, Uri.parse('$baseUrl/discounts/discount-id'));
      deleteRequested = true;
      return http.Response(jsonEncode({'message': 'Discount deleted'}), 200);
    });
    final dataSource = DiscountsRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final discounts = await dataSource.getDiscounts();
    final created = await dataSource.saveDiscount(
      name: 'Happy Hour',
      type: DiscountType.percentage,
      value: 15,
      description: 'Diskon sore',
      isActive: true,
    );
    final updated = await dataSource.saveDiscount(
      discountId: 'discount-id',
      name: 'Happy Hour',
      type: DiscountType.nominal,
      value: 10000,
      description: 'Potongan sore',
      isActive: false,
    );
    await dataSource.deleteDiscount('discount-id');

    expect(discounts.single.type, DiscountType.percentage);
    expect(created.name, 'Happy Hour');
    expect(updated.type, DiscountType.nominal);
    expect(updated.isActive, isFalse);
    expect(deleteRequested, isTrue);
  });

  test('rejects requests when no login token is available', () async {
    final dataSource = DiscountsRemoteDataSource(
      MockClient((_) async => http.Response('[]', 200)),
      baseUrl,
      () async => null,
    );

    await expectLater(dataSource.getDiscounts(), throwsException);
  });
}

Map<String, Object> _discountJson({
  String name = 'Member',
  String type = 'percentage',
  num value = 10,
  String description = 'Diskon member',
  bool isActive = true,
}) => {
  '_id': 'discount-id',
  'name': name,
  'type': type,
  'value': value,
  'description': description,
  'is_active': isActive,
};
