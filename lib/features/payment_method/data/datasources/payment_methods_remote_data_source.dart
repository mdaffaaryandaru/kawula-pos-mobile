import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../models/payment_method_model.dart';

class PaymentMethodsRemoteDataSource {
  const PaymentMethodsRemoteDataSource(
    this._client,
    this._baseUrl,
    this._readToken,
  );

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    final response = await _client.get(
      _uri('payment-methods'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar metode pembayaran tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException(
              'Data metode pembayaran dari server tidak valid.',
            );
          }
          return PaymentMethodModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<PaymentMethodModel> getPaymentMethod(String paymentMethodId) async {
    final response = await _client.get(
      _uri('payment-methods/$paymentMethodId'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Respons detail metode pembayaran tidak valid.');
    }
    return PaymentMethodModel.fromJson(body);
  }

  Future<PaymentMethodModel> savePaymentMethod({
    String? paymentMethodId,
    required String? code,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    if (paymentMethodId == null && (code == null || code.trim().length < 2)) {
      throw const ApiException('Kode metode pembayaran minimal 2 karakter.');
    }
    final payload = <String, Object?>{
      'name': name.trim(),
      'description': description.trim(),
      'is_active': isActive,
      if (paymentMethodId == null) 'code': code?.trim().toUpperCase(),
    };
    final headers = await _authorizedJsonHeaders();
    final response = paymentMethodId == null
        ? await _client.post(
            _uri('payment-methods'),
            headers: headers,
            body: jsonEncode(payload),
          )
        : await _client.patch(
            _uri('payment-methods/$paymentMethodId'),
            headers: headers,
            body: jsonEncode(payload),
          );
    final body = _decodeResponse(response);
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Respons server metode pembayaran tidak valid.');
    }
    return PaymentMethodModel.fromJson(body);
  }

  Future<void> deletePaymentMethod(String paymentMethodId) async {
    final response = await _client.delete(
      _uri('payment-methods/$paymentMethodId'),
      headers: await _authorizedHeaders(),
    );
    _decodeResponse(response);
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
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
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
      throw ApiException(
        message is String
            ? message
            : 'Permintaan gagal dengan kode ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
