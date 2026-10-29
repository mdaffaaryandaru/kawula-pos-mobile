import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/payment_method/data/datasources/payment_methods_remote_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test(
    'uses the existing list, detail, create, update, and delete endpoints',
    () async {
      final requests = <String>[];
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        requests.add('${request.method} ${request.url.path}');
        if (request.method == 'GET' &&
            request.url.path == '/api/payment-methods') {
          return http.Response(jsonEncode([_methodJson()]), 200);
        }
        if (request.method == 'GET') {
          expect(request.url, Uri.parse('$baseUrl/payment-methods/cash-id'));
          return http.Response(jsonEncode(_methodJson()), 200);
        }
        if (request.method == 'POST') {
          expect(request.url, Uri.parse('$baseUrl/payment-methods'));
          expect(jsonDecode(request.body), {
            'name': 'Transfer Bank',
            'description': 'Pembayaran melalui transfer bank',
            'is_active': true,
            'code': 'BANK_TRANSFER',
          });
          return http.Response(
            jsonEncode(
              _methodJson(name: 'Transfer Bank', code: 'BANK_TRANSFER'),
            ),
            201,
          );
        }
        if (request.method == 'PATCH') {
          expect(request.url, Uri.parse('$baseUrl/payment-methods/cash-id'));
          expect(jsonDecode(request.body), {
            'name': 'Tunai',
            'description': 'Pembayaran tunai',
            'is_active': false,
          });
          return http.Response(
            jsonEncode(
              _methodJson(
                name: 'Tunai',
                description: 'Pembayaran tunai',
                isActive: false,
              ),
            ),
            200,
          );
        }
        expect(request.method, 'DELETE');
        expect(request.url, Uri.parse('$baseUrl/payment-methods/cash-id'));
        return http.Response(
          jsonEncode({'message': 'Metode pembayaran berhasil dihapus'}),
          200,
        );
      });
      final dataSource = PaymentMethodsRemoteDataSource(
        client,
        baseUrl,
        () async => 'jwt-token',
      );

      final methods = await dataSource.getPaymentMethods();
      final detail = await dataSource.getPaymentMethod('cash-id');
      final created = await dataSource.savePaymentMethod(
        code: 'bank_transfer',
        name: 'Transfer Bank',
        description: 'Pembayaran melalui transfer bank',
        isActive: true,
      );
      final updated = await dataSource.savePaymentMethod(
        paymentMethodId: 'cash-id',
        code: null,
        name: 'Tunai',
        description: 'Pembayaran tunai',
        isActive: false,
      );
      await dataSource.deletePaymentMethod('cash-id');

      expect(methods.single.code, 'CASH');
      expect(detail.name, 'Cash');
      expect(created.code, 'BANK_TRANSFER');
      expect(updated.isActive, isFalse);
      expect(requests, [
        'GET /api/payment-methods',
        'GET /api/payment-methods/cash-id',
        'POST /api/payment-methods',
        'PATCH /api/payment-methods/cash-id',
        'DELETE /api/payment-methods/cash-id',
      ]);
    },
  );

  test('rejects requests without an authentication token', () async {
    final dataSource = PaymentMethodsRemoteDataSource(
      MockClient((_) async => http.Response('[]', 200)),
      baseUrl,
      () async => null,
    );

    await expectLater(dataSource.getPaymentMethods(), throwsException);
  });

  test('requires a code when creating a payment method', () async {
    final dataSource = PaymentMethodsRemoteDataSource(
      MockClient((_) async => http.Response('{}', 201)),
      baseUrl,
      () async => 'jwt-token',
    );

    await expectLater(
      dataSource.savePaymentMethod(
        code: null,
        name: 'Tunai',
        description: '',
        isActive: true,
      ),
      throwsException,
    );
  });
}

Map<String, Object> _methodJson({
  String name = 'Cash',
  String code = 'CASH',
  String description = 'Pembayaran tunai langsung di kasir',
  bool isActive = true,
}) => {
  '_id': 'cash-id',
  'name': name,
  'code': code,
  'description': description,
  'is_active': isActive,
};
