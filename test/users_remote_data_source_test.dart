import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/users/data/datasources/users_remote_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test('loads users and maps whether their PIN has been configured', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url, Uri.parse('$baseUrl/users'));
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      return http.Response(
        jsonEncode([
          {
            '_id': 'cashier-id',
            'name': 'Kasir Baru',
            'email': 'kasir@kawula.id',
            'role': 'Kasir',
            'has_pin': false,
          },
        ]),
        200,
      );
    });
    final dataSource = UsersRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final users = await dataSource.getUsers();

    expect(users, hasLength(1));
    expect(users.single.id, 'cashier-id');
    expect(users.single.hasPin, isFalse);
  });

  test('updates only the PIN through the existing user endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PATCH');
      expect(request.url, Uri.parse('$baseUrl/users/cashier-id'));
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      expect(jsonDecode(request.body), {'pin': '5678'});
      return http.Response(
        jsonEncode({
          '_id': 'cashier-id',
          'name': 'Kasir Baru',
          'email': 'kasir@kawula.id',
          'role': 'Kasir',
          'has_pin': true,
        }),
        200,
      );
    });
    final dataSource = UsersRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final user = await dataSource.updatePin(userId: 'cashier-id', pin: '5678');

    expect(user.id, 'cashier-id');
    expect(user.hasPin, isTrue);
  });
}
