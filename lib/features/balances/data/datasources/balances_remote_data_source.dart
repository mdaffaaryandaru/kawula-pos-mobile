import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../models/balance_models.dart';

class BalancesRemoteDataSource {
  const BalancesRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<BalanceAccountModel>> getBalances() async {
    final body = _decodeResponse(
      await _client.get(_uri('balances'), headers: await _authorizedHeaders()),
    );
    if (body is! List) {
      throw const ApiException('Respons daftar saldo tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data saldo dari server tidak valid.');
          }
          return BalanceAccountModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<List<BalanceHistoryEntryModel>> getHistory() async {
    final body = _decodeResponse(
      await _client.get(
        _uri('balances/history'),
        headers: await _authorizedHeaders(),
      ),
    );
    if (body is! List) {
      throw const ApiException('Respons riwayat saldo tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException(
              'Data riwayat saldo dari server tidak valid.',
            );
          }
          return BalanceHistoryEntryModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> recordExpense({
    required String paymentMethod,
    required num amount,
    required String notes,
  }) async {
    _decodeResponse(
      await _client.post(
        _uri('balances/expense'),
        headers: await _authorizedJsonHeaders(),
        body: jsonEncode({
          'payment_method': paymentMethod,
          'amount': amount,
          'notes': notes.trim(),
        }),
      ),
    );
  }

  Future<void> adjustBalance({
    required String paymentMethod,
    required num actualBalance,
    required String notes,
  }) async {
    _decodeResponse(
      await _client.post(
        _uri('balances/adjust'),
        headers: await _authorizedJsonHeaders(),
        body: jsonEncode({
          'payment_method': paymentMethod,
          'actual_balance': actualBalance,
          'notes': notes.trim(),
        }),
      ),
    );
  }

  Uri _uri(String path) {
    final baseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse('$baseUrl/$path');
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sesi login tidak ditemukan. Silakan masuk lagi.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, String>> _authorizedJsonHeaders() async => {
    ...await _authorizedHeaders(),
    'Content-Type': 'application/json',
  };

  Object? _decodeResponse(http.Response response) {
    Object? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException(
            'Permintaan gagal dengan kode ${response.statusCode}.',
            statusCode: response.statusCode,
          );
        }
        throw const ApiException('Respons server tidak valid.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']
          : null;
      final errorMessage = message is String
          ? message
          : message is List
          ? message.whereType<String>().join('\n')
          : null;
      throw ApiException(
        errorMessage?.isNotEmpty == true
            ? errorMessage!
            : 'Permintaan gagal dengan kode ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
