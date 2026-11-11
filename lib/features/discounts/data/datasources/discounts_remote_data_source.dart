// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/discounts/data/models/discount_model.dart';
import 'package:kawula_pos/features/discounts/domain/entities/discount_definition.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

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
