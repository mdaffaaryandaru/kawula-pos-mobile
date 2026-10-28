import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../framework/core/exceptions/api_exception.dart';
import '../models/store_settings_model.dart';

class StoreSettingsRemoteDataSource {
  StoreSettingsRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<StoreSettingsModel> getSettings() async {
    final response = await _client.get(
      _uri('store-settings'),
      headers: await _authorizedHeaders(),
    );
    return StoreSettingsModel.fromJson(_decodeObject(response));
  }

  Future<StoreSettingsModel> updateSettings(StoreSettingsModel settings) async {
    final response = await _client.patch(
      _uri('store-settings'),
      headers: await _authorizedJsonHeaders(),
      body: jsonEncode(settings.toJson()),
    );
    return StoreSettingsModel.fromJson(_decodeObject(response));
  }

  Future<String> uploadLogo(XFile image) async {
    final namedExtension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : '';
    final mimeExtension = switch (image.mimeType?.toLowerCase()) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      _ => '',
    };
    final extension =
        const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(namedExtension)
        ? namedExtension
        : mimeExtension;
    if (!const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(extension)) {
      throw const ApiException(
        'Format logo harus JPG, JPEG, PNG, WEBP, atau GIF.',
      );
    }
    final bytes = await image.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw const ApiException('Ukuran logo maksimal 2 MB.');
    }
    final request = http.MultipartRequest(
      'POST',
      _uri('store-settings/upload-logo'),
    );
    request.headers.addAll(await _authorizedHeaders());
    final filename =
        const {'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(namedExtension)
        ? image.name
        : 'store-logo.$extension';
    request.files.add(
      http.MultipartFile.fromBytes('logo', bytes, filename: filename),
    );
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decodeObject(response);
    final url = body['url'];
    if (url is! String || url.isEmpty) {
      throw const ApiException('URL logo dari server tidak valid.');
    }
    return url;
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
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Respons server tidak valid.');
  }
}
