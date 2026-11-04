import 'package:http/http.dart' as http;

import 'package:kawula_pos/framework/core/network/auth_session_expiry_handler.dart';

class SessionAwareHttpClient extends http.BaseClient {
  SessionAwareHttpClient(this._inner, this._sessionExpiryHandler);

  final http.Client _inner;
  final AuthSessionExpiryHandler _sessionExpiryHandler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    final token = _bearerToken(request.headers);
    if (response.statusCode == 401 && token != null) {
      await _sessionExpiryHandler.handleUnauthorized(token);
    }
    return response;
  }

  @override
  void close() {
    _inner.close();
  }

  String? _bearerToken(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() != 'authorization') continue;
      final value = entry.value.trim();
      if (!value.toLowerCase().startsWith('bearer ')) return null;
      final token = value.substring(7).trim();
      return token.isEmpty ? null : token;
    }
    return null;
  }
}
