// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/tables/data/models/managed_table_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

class TablesRemoteDataSource {
  const TablesRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<ManagedTableModel>> getTables() async {
    final response = await _client.get(
      _uri('tables'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar meja tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data meja dari server tidak valid.');
          }
          return ManagedTableModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<ManagedTableModel> saveTable({
    String? tableId,
    required String name,
    required String areaId,
    required int capacity,
    required String status,
    required bool isActive,
  }) async {
    final payload = <String, Object>{
      'name': name.trim(),
      'area_id': areaId,
      'capacity': capacity,
      'status': status,
      'is_active': isActive,
    };
    final uri = _uri(tableId == null ? 'tables' : 'tables/$tableId');
    final headers = await _authorizedJsonHeaders();
    final response = tableId == null
        ? await _client.post(uri, headers: headers, body: jsonEncode(payload))
        : await _client.patch(uri, headers: headers, body: jsonEncode(payload));
    final body = _decodeResponse(response);
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Respons server meja tidak valid.');
    }
    return ManagedTableModel.fromJson(body);
  }

  Future<void> deleteTable(String tableId) async {
    final response = await _client.delete(
      _uri('tables/$tableId'),
      headers: await _authorizedHeaders(),
    );
    _decodeResponse(response);
  }

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    return {
      ...buildAuthorizationHeaders(token),
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
