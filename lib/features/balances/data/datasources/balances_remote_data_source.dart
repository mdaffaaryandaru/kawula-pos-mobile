// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/balances/data/models/balance_models.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

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

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    return {...buildAuthorizationHeaders(token), 'Accept': 'application/json'};
  }

  Future<Map<String, String>> _authorizedJsonHeaders() async => {
    ...await _authorizedHeaders(),
    'Content-Type': 'application/json',
  };

  Object? _decodeResponse(http.Response response) {
    return decodeApiResponse(
      response,
      allowEmptySuccess: false,
      allowErrorMessageLists: true,
      emptyErrorMessageUsesFallback: true,
    );
  }
}
