import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../models/product_unit_model.dart';

class ProductUnitsRemoteDataSource {
  ProductUnitsRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<ProductUnitModel>> getProductUnits() async {
    final uri = _uri();
    try {
      final headers = await _authorizedHeaders();
      final response = await _client.get(uri, headers: headers);
      if (kDebugMode) {
        debugPrint(
          '[Product Units API] GET $uri '
          '(****** ${headers['Authorization']?.startsWith('Bearer ') == true}) '
          '-> ${response.statusCode}${_responseMessage(response)}',
        );
      }
      final decoded = _decodeResponse(response);
      if (decoded is! List) {
        throw const ApiException('Respons daftar satuan tidak valid.');
      }
      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const ApiException('Data satuan inventori tidak valid.');
            }
            return ProductUnitModel.fromJson(item);
          })
          .toList(growable: false);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Product Units API] GET $uri failed: $error');
      }
      rethrow;
    }
  }

  Future<ProductUnitModel> saveProductUnit({
    String? unitId,
    required String name,
    required String abbreviation,
    required String description,
    required bool isActive,
  }) async {
    final uri = _uri(unitId);
    final method = unitId == null ? 'POST' : 'PATCH';
    final payload = jsonEncode({
      'name': name,
      'abbreviation': abbreviation,
      'description': description,
      'is_active': isActive,
    });
    final headers = await _authorizedJsonHeaders();
    late final http.Response response;
    if (unitId == null) {
      response = await _client.post(uri, headers: headers, body: payload);
    } else {
      response = await _client.patch(uri, headers: headers, body: payload);
    }
    if (kDebugMode) {
      debugPrint(
        '[Product Units API] $method $uri -> ${response.statusCode}'
        '${_responseMessage(response)}',
      );
    }
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons satuan tidak valid.');
    }
    return ProductUnitModel.fromJson(decoded);
  }

  Future<void> deleteProductUnit(String unitId) async {
    final uri = _uri(unitId);
    final response = await _client.delete(
      uri,
      headers: await _authorizedHeaders(),
    );
    if (kDebugMode) {
      debugPrint(
        '[Product Units API] DELETE $uri -> ${response.statusCode}'
        '${_responseMessage(response)}',
      );
    }
    _decodeResponse(response);
  }

  Uri _uri([String? unitId]) {
    final baseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final path = unitId == null ? 'product-units' : 'product-units/$unitId';
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
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Permintaan gagal dengan kode ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      throw const ApiException('Respons server satuan tidak valid.');
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

  String _responseMessage(http.Response response) {
    if (response.statusCode < 400) return '';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return ' — ${decoded['message']}';
      }
    } on FormatException {
      return '';
    }
    return '';
  }
}
