// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/table_areas/data/models/table_area_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

class TableAreasRemoteDataSource {
  const TableAreasRemoteDataSource(
    this._client,
    this._baseUrl,
    this._readToken,
  );

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<TableAreaModel>> getTableAreas() async {
    final response = await _client.get(
      _uri('table-areas'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar area tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data area dari server tidak valid.');
          }
          return TableAreaModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<TableAreaModel> saveTableArea({
    String? areaId,
    required String name,
    required String outletId,
    required String description,
    required bool isActive,
  }) async {
    final payload = <String, Object>{
      'name': name.trim(),
      'outlet_id': outletId,
      'description': description.trim(),
      'is_active': isActive,
    };
    final uri = _uri(areaId == null ? 'table-areas' : 'table-areas/$areaId');
    final headers = await _authorizedJsonHeaders();
    final response = areaId == null
        ? await _client.post(uri, headers: headers, body: jsonEncode(payload))
        : await _client.patch(uri, headers: headers, body: jsonEncode(payload));
    final body = _decodeResponse(response);
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Respons server area tidak valid.');
    }
    return TableAreaModel.fromJson(body);
  }

  Future<void> deleteTableArea(String areaId) async {
    final response = await _client.delete(
      _uri('table-areas/$areaId'),
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
