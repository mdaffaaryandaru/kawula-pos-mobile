import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../../domain/entities/variant_group_definition.dart';
import '../models/variant_group_models.dart';

class VariantGroupsRemoteDataSource {
  VariantGroupsRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<VariantGroupDefinitionModel>> getVariantGroupDefinitions() async {
    final response = await _client.get(
      _uri('variant-groups'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response, endpoint: 'GET /api/variant-groups');
    if (body is! List) {
      throw const ApiException('Respons daftar grup varian tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException(
              'Data grup varian dari server tidak valid.',
            );
          }
          return VariantGroupDefinitionModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<List<VariantRecipeReferenceModel>>
  getVariantRecipeInventoryReferences() async {
    final response = await _client.get(
      _uri('inventories'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(
      response,
      endpoint: 'GET /api/inventories',
    );
    if (body is! List) {
      throw const ApiException('Respons referensi bahan varian tidak valid.');
    }
    final inventories = body
        .whereType<Map<String, dynamic>>()
        .map(VariantRecipeReferenceModel.fromJson)
        .toList(growable: false);
    if (inventories.length != body.length) {
      throw const ApiException(
        'Data referensi bahan dari server tidak valid.',
      );
    }
    return inventories;
  }

  Future<VariantGroupDefinitionModel> saveVariantGroup({
    String? groupId,
    required String name,
    required bool isRequired,
    required int minSelection,
    required int maxSelection,
    required List<VariantOptionDefinition> options,
  }) async {
    final payload = <String, Object>{
      'name': name.trim(),
      'is_required': isRequired,
      'min_selection': minSelection,
      'max_selection': maxSelection,
      'options': options
          .map(
            (option) => {
              'name': option.name.trim(),
              'price_adjustment': option.priceAdjustment,
              if (option.recipes.isNotEmpty)
                'recipes': option.recipes
                    .map(
                      (recipe) => {
                        'inventory_id': recipe.inventoryId,
                        'quantity': recipe.quantity,
                        'unit_id': recipe.unitId,
                        'conversion_factor': recipe.conversionFactor,
                      },
                    )
                    .toList(growable: false),
            },
          )
          .toList(growable: false),
    };
    final uri = _uri(
      groupId == null ? 'variant-groups' : 'variant-groups/$groupId',
    );
    final headers = {
      ...await _authorizedHeaders(),
      'Content-Type': 'application/json',
    };
    final response = groupId == null
        ? await _client.post(uri, headers: headers, body: jsonEncode(payload))
        : await _client.patch(uri, headers: headers, body: jsonEncode(payload));
    final body = _decodeResponse(
      response,
      endpoint: '${groupId == null ? 'POST' : 'PATCH'} /api/variant-groups',
    );
    if (body is! Map<String, dynamic>) {
      throw const ApiException('Respons server tidak valid.');
    }
    return VariantGroupDefinitionModel.fromJson(body);
  }

  Future<void> deleteVariantGroup(String groupId) async {
    final response = await _client.delete(
      _uri('variant-groups/$groupId'),
      headers: await _authorizedHeaders(),
    );
    _decodeResponse(response, endpoint: 'DELETE /api/variant-groups/$groupId');
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

  Object? _decodeResponse(http.Response response, {required String endpoint}) {
    Object? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiException(
            '$endpoint: permintaan gagal dengan kode ${response.statusCode}.',
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
      final errorMessage = message is String
          ? message
          : message is List
          ? message.whereType<String>().join('\n')
          : null;
      throw ApiException(
        '$endpoint: ${errorMessage?.isNotEmpty == true ? errorMessage : 'Permintaan gagal dengan kode ${response.statusCode}.'}',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
