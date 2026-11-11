// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/outlets/data/models/outlet_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

class OutletsRemoteDataSource {
  const OutletsRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<OutletModel>> getOutlets() async {
    final response = await _client.get(
      _uri('outlets'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar outlet tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data outlet dari server tidak valid.');
          }
          return OutletModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<OutletModel> saveOutlet({
    String? outletId,
    required String name,
    required String code,
    required String address,
    required String phone,
    required bool isActive,
  }) async {
    final payload = <String, Object>{
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'address': address.trim(),
      'phone': phone.trim(),
      'is_active': isActive,
    };
    final uri = _uri(outletId == null ? 'outlets' : 'outlets/$outletId');
    final headers = await _authorizedJsonHeaders();
    final response = outletId == null
        ? await _client.post(uri, headers: headers, body: jsonEncode(payload))
        : await _client.patch(uri, headers: headers, body: jsonEncode(payload));
    final body = _decodeResponse(response);
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Respons server outlet tidak valid.');
    }
    return OutletModel.fromJson(body);
  }

  Future<void> deleteOutlet(String outletId) async {
    final response = await _client.delete(
      _uri('outlets/$outletId'),
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
