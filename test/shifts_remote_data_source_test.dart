import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/shifts/data/datasources/shifts_remote_data_source.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';

  group('ShiftsRemoteDataSource', () {
    test('requests the active shift with the saved bearer token', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url, Uri.parse('$baseUrl/shifts/active'));
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        return http.Response(
          jsonEncode({
            '_id': 'shift-id',
            'status': 'open',
            'start_time': '2026-10-27T02:00:00.000Z',
            'starting_cash': 50000,
            'expected_cash': 65000,
            'total_sales': 15000,
            'total_transactions': 1,
            'outlet_id': {'_id': 'outlet-id', 'name': 'Outlet Utama'},
          }),
          200,
        );
      });
      final dataSource = _createDataSource(client);

      final shift = await dataSource.getActive();

      expect(shift?.id, 'shift-id');
      expect(shift?.outletName, 'Outlet Utama');
      expect(shift?.expectedCash, 65000);
      expect(shift?.totalTransactions, 1);
    });

    test('returns null when the user has not opened a shift', () async {
      final client = MockClient((request) async {
        expect(request.url, Uri.parse('$baseUrl/shifts/active'));
        return http.Response('null', 200);
      });

      expect(await _createDataSource(client).getActive(), isNull);
    });

    test('returns null when the backend responds with an empty body', () async {
      final client = MockClient((request) async {
        expect(request.url, Uri.parse('$baseUrl/shifts/active'));
        return http.Response('', 200);
      });

      expect(await _createDataSource(client).getActive(), isNull);
    });

    test('loads available cash from the cashier endpoint', () async {
      final client = MockClient((request) async {
        expect(request.url, Uri.parse('$baseUrl/balances/cash-availability'));
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        return http.Response(
          jsonEncode({
            'global_balance': 100000,
            'reserved_cash': 25000,
            'available_cash': 75000,
          }),
          200,
        );
      });

      final result = await _createDataSource(client).getCashAvailability();

      expect(result.availableCash, 75000);
    });

    test('opens a shift with the backend request shape', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, Uri.parse('$baseUrl/shifts/open'));
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        expect(jsonDecode(request.body), {
          'starting_cash': 50000,
          'pin': '1234',
        });
        return http.Response(jsonEncode({'_id': 'shift-id'}), 201);
      });

      await _createDataSource(client)
          .openShift(startingCash: 50000, pin: '1234');
    });

    test('closes a shift with actual cash, pin, and optional notes', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, Uri.parse('$baseUrl/shifts/shift-id/close'));
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        expect(jsonDecode(request.body), {
          'actual_cash': 48000,
          'pin': '1234',
          'notes': 'Kas kecil kurang',
        });
        return http.Response(
          jsonEncode({
            '_id': 'shift-id',
            'status': 'closed',
            'start_time': '2026-10-27T02:00:00.000Z',
            'end_time': '2026-10-27T10:00:00.000Z',
            'starting_cash': 50000,
            'expected_cash': 55000,
            'actual_cash': 48000,
            'cash_difference': -7000,
            'total_sales': 5000,
            'total_transactions': 1,
          }),
          200,
        );
      });

      final shift = await _createDataSource(client).closeShift(
        shiftId: 'shift-id',
        actualCash: 48000,
        pin: '1234',
        notes: 'Kas kecil kurang',
      );

      expect(shift.status, 'closed');
      expect(shift.actualCash, 48000);
      expect(shift.cashDifference, -7000);
      expect(shift.endTime, isNotNull);
    });

    test('omits PIN when closing without a PIN', () async {
      final client = MockClient((request) async {
        expect(jsonDecode(request.body), {'actual_cash': 50000});
        return http.Response(
          jsonEncode({
            '_id': 'shift-id',
            'status': 'closed',
            'start_time': '2026-10-27T02:00:00.000Z',
            'starting_cash': 50000,
            'expected_cash': 50000,
            'actual_cash': 50000,
            'cash_difference': 0,
            'total_sales': 0,
            'total_transactions': 0,
          }),
          200,
        );
      });

      await _createDataSource(client)
          .closeShift(shiftId: 'shift-id', actualCash: 50000);
    });
  });
}

ShiftsRemoteDataSource _createDataSource(http.Client client) {
  return ShiftsRemoteDataSource(
    client,
    'http://localhost:3001/api',
    () async => 'jwt-token',
  );
}
