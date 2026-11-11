// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/inventories/data/models/inventory_models.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

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

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    return {...buildAuthorizationHeaders(token), 'Accept': 'application/json'};
  }

  Object? _decodeResponse(http.Response response) {
    return decodeApiResponse(
      response,
      invalidResponseMessage: 'Respons server inventori tidak valid.',
      trimEmptyBody: false,
      allowErrorMessageLists: true,
      emptyErrorMessageUsesFallback: true,
    );
  }
}
