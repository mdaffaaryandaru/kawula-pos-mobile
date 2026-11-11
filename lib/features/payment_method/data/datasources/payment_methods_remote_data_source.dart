// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/payment_method/data/models/payment_method_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

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

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    return {...buildAuthorizationHeaders(token), 'Accept': 'application/json'};
  }

  Future<Map<String, String>> _authorizedJsonHeaders() async => {
    ...await _authorizedHeaders(),
    'Content-Type': 'application/json',
  };

  Object? _decodeResponse(http.Response response) =>
      decodeApiResponse(response);
}
