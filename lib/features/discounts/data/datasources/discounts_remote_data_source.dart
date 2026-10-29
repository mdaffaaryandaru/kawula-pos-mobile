import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../../domain/entities/discount_definition.dart';
import '../models/discount_model.dart';

class DiscountsRemoteDataSource {
  const DiscountsRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<DiscountModel>> getDiscounts() async {
    final response = await _client.get(
      _uri('discounts'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar diskon tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data diskon dari server tidak valid.');
          }
          return DiscountModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<DiscountModel> saveDiscount({
    String? discountId,
    required String name,
    required DiscountType type,
    required num value,
    required String description,
    required bool isActive,
  }) async {
    final payload = <String, Object>{
      'name': name.trim(),
      'type': type.apiValue,
      'value': value,
      'description': description.trim(),
      'is_active': isActive,
    };
    final headers = await _authorizedJsonHeaders();
    final response = discountId == null
        ? await _client.post(
            _uri('discounts'),
            headers: headers,
            body: jsonEncode(payload),
          )
        : await _client.patch(
            _uri('discounts/$discountId'),
            headers: headers,
            body: jsonEncode(payload),
          );
    final body = _decodeResponse(response);
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Respons server diskon tidak valid.');
    }
    return DiscountModel.fromJson(body);
  }

  Future<void> deleteDiscount(String discountId) async {
    final response = await _client.delete(
      _uri('discounts/$discountId'),
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
