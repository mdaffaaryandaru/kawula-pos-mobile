import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/balances/data/datasources/balances_remote_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test('loads balance accounts and history from existing endpoints', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], isNotEmpty);
      if (request.url.path == '/api/balances') {
        return http.Response(
          jsonEncode([
            {'_id': 'cash-id', 'payment_method': 'CASH', 'balance': 125000},
          ]),
          200,
        );
      }
      expect(request.url, Uri.parse('$baseUrl/balances/history'));
      return http.Response(
        jsonEncode([
          {
            '_id': 'history-id',
            'payment_method': 'CASH',
            'type': 'expense',
            'amount': -25000,
            'final_balance': 125000,
            'notes': 'Belanja operasional',
            'createdAt': '2026-10-27T09:00:00.000Z',
            'created_by': {'name': 'Admin', 'email': 'admin@kawula.id'},
          },
        ]),
        200,
      );
    });
    final dataSource = _createDataSource(client);

    final balances = await dataSource.getBalances();
    final history = await dataSource.getHistory();

    expect(balances.single.balance, 125000);
    expect(history.single.type, 'expense');
    expect(history.single.createdBy, 'Admin');
  });

  test(
    'sends expense and balance adjustment using backend field names',
    () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], isNotEmpty);
        if (request.url.path == '/api/balances/expense') {
          expect(jsonDecode(request.body), {
            'payment_method': 'CASH',
            'amount': 25000,
            'notes': 'Belanja operasional',
          });
        } else {
          expect(request.url, Uri.parse('$baseUrl/balances/adjust'));
          expect(jsonDecode(request.body), {
            'payment_method': 'CASH',
            'actual_balance': 125000,
            'notes': 'Hasil hitung kas',
          });
        }
        return http.Response(jsonEncode({'message': 'Berhasil'}), 200);
      });
      final dataSource = _createDataSource(client);

      await dataSource.recordExpense(
        paymentMethod: 'CASH',
        amount: 25000,
        notes: ' Belanja operasional ',
      );
      await dataSource.adjustBalance(
        paymentMethod: 'CASH',
        actualBalance: 125000,
        notes: ' Hasil hitung kas ',
      );

      expect(requestCount, 2);
    },
  );
}

BalancesRemoteDataSource _createDataSource(http.Client client) {
  return BalancesRemoteDataSource(
    client,
    'http://localhost:3001/api',
    () async => 'jwt-token',
  );
}
