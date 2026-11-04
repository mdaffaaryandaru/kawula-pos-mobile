// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/products/data/models/catalog_models.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<CatalogProductModel>> getProducts() async {
    final response = await _client.get(
      _uri('products'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar produk tidak valid.');
    }
    final products = <CatalogProductModel>[];
    for (final item in body) {
      if (item is! Map<String, dynamic>) {
        throw const ApiException('Data produk pada katalog tidak valid.');
      }
      final product = CatalogProductModel.fromJson(item);
      if (product.isActive) products.add(product);
    }
    return products;
  }

  Future<List<CatalogCategoryModel>> getCategories() async {
    final response = await _client.get(
      _uri('categories'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar kategori tidak valid.');
    }
    final categories = <CatalogCategoryModel>[];
    for (final item in body) {
      if (item is! Map<String, dynamic>) {
        throw const ApiException('Data kategori pada katalog tidak valid.');
      }
      final category = CatalogCategoryModel.fromJson(item);
      if (category.isActive) categories.add(category);
    }
    return categories;
  }

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    return {
      ...buildAuthorizationHeaders(token),
      'Accept': 'application/json',
    };
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
      throw const ApiException('Respons server tidak valid.');
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
