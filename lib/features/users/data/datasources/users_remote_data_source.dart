// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/auth/data/models/auth_user_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

class UsersRemoteDataSource {
  UsersRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<AuthUserModel>> getUsers() async {
    final response = await _client.get(
      _uri('users'),
      headers: await _authorizedHeaders(),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw const ApiException('Respons daftar pengguna tidak valid.');
    }
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data pengguna tidak valid.');
          }
          return AuthUserModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<AuthUserModel> updatePin({
    required String userId,
    required String pin,
  }) async {
    final response = await _client.patch(
      _uri('users/$userId'),
      headers: await _authorizedHeaders(),
      body: jsonEncode({'pin': pin}),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons pengguna tidak valid.');
    }
    return AuthUserModel.fromJson(decoded);
  }

  Future<AuthUserModel> saveUser({
    String? userId,
    required String name,
    required String email,
    required String password,
    required String pin,
    required String role,
  }) async {
    final payload = <String, String>{
      'name': name,
      'email': email,
      'role': role,
      if (password.isNotEmpty) 'password': password,
      if (pin.isNotEmpty) 'pin': pin,
    };
    final response = userId == null
        ? await _client.post(
            _uri('users'),
            headers: await _authorizedHeaders(),
            body: jsonEncode(payload),
          )
        : await _client.patch(
            _uri('users/$userId'),
            headers: await _authorizedHeaders(),
            body: jsonEncode(payload),
          );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons pengguna tidak valid.');
    }
    return AuthUserModel.fromJson(decoded);
  }

  Future<void> deleteUser(String userId) async {
    final response = await _client.delete(
      _uri('users/$userId'),
      headers: await _authorizedHeaders(),
    );
    _decodeResponse(response);
  }

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    return {
      ...buildAuthorizationHeaders(token),
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Object? _decodeResponse(http.Response response) {
    return decodeApiResponse(
      response,
      allowEmptySuccess: false,
      allowErrorMessageLists: true,
      emptyErrorMessageUsesFallback: true,
    );
  }
}
