import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../../../auth/data/models/auth_user_model.dart';

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
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
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
