import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../models/inventory_models.dart';

class InventoryRemoteDataSource {
  InventoryRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<InventoryItemModel>> getInventories() async {
    final response = await _get('inventories');
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw const ApiException('Respons daftar bahan inventori tidak valid.');
    }
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data bahan inventori tidak valid.');
          }
          return InventoryItemModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<List<ProductUnitModel>> getProductUnits() async {
    final response = await _get('product-units');
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
  }

  Future<http.Response> _get(String path) async {
    final uri = _uri(path);
    try {
      final headers = await _authorizedHeaders();
      final response = await _client.get(uri, headers: headers);
      if (kDebugMode) {
        debugPrint(
          '[Inventory API] GET $uri '
          '(Bearer header: ${headers['Authorization']?.startsWith('Bearer ') == true}) '
          '-> ${response.statusCode}${_responseMessage(response)}',
        );
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Inventory API] GET $uri failed: $error');
      }
      rethrow;
    }
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
      throw const ApiException('Respons server inventori tidak valid.');
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
