// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/auth/data/models/auth_user_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

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

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = decodeApiResponse(
      response,
      allowEmptySuccess: false,
      allowErrorMessageLists: true,
      emptyErrorMessageUsesFallback: true,
    );
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Respons server tidak valid.');
  }
}
