import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../models/product_management_models.dart';

class ProductManagementRemoteDataSource {
  ProductManagementRemoteDataSource(
    this._client,
    this._baseUrl,
    this._readToken,
  );

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<ManagedProductModel>> getProducts() async {
    final response = await _client.get(
      _uri('products'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar produk tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data produk dari server tidak valid.');
          }
          return ManagedProductModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<List<ManagedVariantGroupModel>> getVariantGroups() async {
    final response = await _client.get(
      _uri('variant-groups'),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
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
          return ManagedVariantGroupModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<List<String>> uploadProductImages(List<XFile> images) async {
    if (images.isEmpty) return const [];
    if (images.length > 5) {
      throw const ApiException('Maksimal 5 gambar produk sekali upload.');
    }

    final request = http.MultipartRequest('POST', _uri('products/upload'));
    request.headers.addAll(await _authorizedHeaders());
    for (final image in images) {
      final filename = image.name;
      final extension = filename.contains('.')
          ? filename.split('.').last.toLowerCase()
          : '';
      if (!const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(extension)) {
        throw ApiException('Format gambar $filename tidak didukung.');
      }
      final bytes = await image.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        throw ApiException('Ukuran gambar $filename melebihi 2 MB.');
      }
      request.files.add(
        http.MultipartFile.fromBytes('images', bytes, filename: filename),
      );
    }
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decodeResponse(response);
    if (body is! Map<String, dynamic> || body['urls'] is! List) {
      throw const ApiException('Respons upload gambar tidak valid.');
    }
    final urls = (body['urls'] as List)
        .map((value) {
          if (value is! String || value.isEmpty) {
            throw const ApiException('URL gambar dari server tidak valid.');
          }
          return value;
        })
        .toList(growable: false);
    if (urls.length != images.length) {
      throw const ApiException('Jumlah gambar yang diunggah tidak sesuai.');
    }
    return urls;
  }

  Future<ManagedProductModel> saveProduct({
    String? productId,
    required String name,
    required num price,
    required num stock,
    required String categoryId,
    required List<String> variantGroupIds,
    required List<ProductImage> images,
    required bool isActive,
  }) async {
    final imagePayload = images
        .map((image) => {'url': image.url, 'is_main': image.isMain})
        .toList(growable: false);
    final payload = <String, Object>{
      'name': name.trim(),
      'price': price,
      'stock': stock,
      'image_url': images.where((image) => image.isMain).firstOrNull?.url ?? '',
      'images': imagePayload,
      'category_id': categoryId,
      'variant_groups': variantGroupIds,
      'is_active': isActive,
    };
    final uri = _uri(productId == null ? 'products' : 'products/$productId');
    final headers = await _authorizedJsonHeaders();
    final response = productId == null
        ? await _client.post(uri, headers: headers, body: jsonEncode(payload))
        : await _client.patch(uri, headers: headers, body: jsonEncode(payload));
    return ManagedProductModel.fromJson(_decodeObject(response));
  }

  Future<void> deleteProduct(String productId) async {
    final response = await _client.delete(
      _uri('products/$productId'),
      headers: await _authorizedHeaders(),
    );
    _decodeResponse(response);
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

  Future<Map<String, String>> _authorizedJsonHeaders() async => {
    ...await _authorizedHeaders(),
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeObject(http.Response response) {
    final body = _decodeResponse(response);
    if (body is Map<String, dynamic>) return body;
    throw const ApiException('Respons server tidak valid.');
  }

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
