// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:kawula_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

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

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    return {...buildAuthorizationHeaders(token), 'Accept': 'application/json'};
  }

  Future<Map<String, String>> _authorizedJsonHeaders() async => {
    ...await _authorizedHeaders(),
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = decodeApiResponse(
      response,
      allowEmptySuccess: true,
      allowErrorMessageLists: true,
      emptyErrorMessageUsesFallback: true,
    );
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Respons server tidak valid.');
  }
}
