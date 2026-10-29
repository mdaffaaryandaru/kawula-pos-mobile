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

  Future<void> saveInventory({
    String? inventoryId,
    required String name,
    required num? stock,
    required String unitId,
    required String category,
    required String description,
    required num buyPrice,
    required num minStock,
    required num? maxStock,
    required bool isActive,
  }) async {
    final payload = <String, Object?>{
      'name': name,
      'unit_id': unitId,
      'category': category,
      'description': description,
      'buy_price': buyPrice,
      'min_stock': minStock,
      'max_stock': maxStock,
      'is_active': isActive,
    };
    if (inventoryId == null && stock != null) payload['stock'] = stock;
    final response = await _send(
      inventoryId == null ? 'POST' : 'PATCH',
      inventoryId == null ? 'inventories' : 'inventories/$inventoryId',
      body: jsonEncode(payload),
    );
    _decodeResponse(response);
  }

  Future<void> deleteInventory(String inventoryId) async {
    final response = await _send('DELETE', 'inventories/$inventoryId');
    _decodeResponse(response);
  }

  Future<void> adjustStock({
    required String inventoryId,
    required String type,
    required num quantity,
    required String notes,
  }) async {
    final response = await _send(
      'POST',
      'inventories/$inventoryId/adjust',
      body: jsonEncode({'type': type, 'quantity': quantity, 'notes': notes}),
    );
    _decodeResponse(response);
  }

  Future<List<InventoryMutationModel>> getMutations(String inventoryId) async {
    final response = await _get('inventories/$inventoryId/mutations');
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw const ApiException('Respons riwayat stok tidak valid.');
    }
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data mutasi stok tidak valid.');
          }
          return InventoryMutationModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    String? body,
  }) async {
    final uri = _uri(path);
    try {
      final headers = await _authorizedHeaders();
      headers['Content-Type'] = 'application/json';
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = body;
      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      if (kDebugMode) {
        debugPrint(
          '[Inventory API] $method $uri -> ${response.statusCode}'
          '${_responseMessage(response)}',
        );
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Inventory API] $method $uri failed: $error');
      }
      rethrow;
    }
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
    if (response.body.isEmpty &&
        response.statusCode >= 200 &&
        response.statusCode < 300) {
      return null;
    }
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
