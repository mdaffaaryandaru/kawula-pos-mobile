import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  group('AuthRemoteDataSource', () {
    test('posts credentials to the backend login endpoint', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, Uri.parse('http://localhost:3001/api/auth/login'));
        expect(jsonDecode(request.body), {
          'email': 'kasir@kawula.id',
          'password': 'password123',
        });
        return http.Response(
          jsonEncode({'access_token': 'jwt-token', 'user': {}}),
          201,
        );
      });
      final dataSource = AuthRemoteDataSource(
        client,
        'http://localhost:3001/api',
      );

      final token = await dataSource.login(
        email: 'kasir@kawula.id',
        password: 'password123',
      );

      expect(token, 'jwt-token');
    });

    test('loads the current profile with a bearer token', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url, Uri.parse('http://localhost:3001/api/auth/me'));
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        return http.Response(
          jsonEncode({
            '_id': 'user-id',
            'name': 'Kasir Kawula',
            'email': 'kasir@kawula.id',
            'role': 'Kasir',
            'has_pin': true,
          }),
          200,
        );
      });
      final dataSource = AuthRemoteDataSource(
        client,
        'http://localhost:3001/api',
      );

      final user = await dataSource.getProfile('jwt-token');

      expect(user.name, 'Kasir Kawula');
      expect(user.id, 'user-id');
      expect(user.role, 'Kasir');
      expect(user.hasPin, isTrue);
    });
  });
}
