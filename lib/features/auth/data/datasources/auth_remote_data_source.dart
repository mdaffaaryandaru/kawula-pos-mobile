import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../models/auth_user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client, this._baseUrl);

  final http.Client _client;
  final String _baseUrl;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _decodeResponse(response);
    final token = body['access_token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Respons login tidak berisi access token.');
    }
    return token;
  }

  Future<AuthUserModel> getProfile(String token) async {
    final response = await _client.get(
      _uri('auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return AuthUserModel.fromJson(_decodeResponse(response));
  }

  Uri _uri(String path) {
    final normalizedBaseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse('$normalizedBaseUrl/$path');
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
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
      throw ApiException(
        _errorMessage(message) ??
            'Permintaan gagal dengan kode ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Respons server tidak valid.');
  }

  String? _errorMessage(Object? message) {
    if (message is String && message.isNotEmpty) return message;
    if (message is List) {
      final messages = message.whereType<String>().toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return null;
  }
}
