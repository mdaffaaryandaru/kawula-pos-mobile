import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../models/active_shift_model.dart';

class ShiftsRemoteDataSource {
  ShiftsRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<ActiveShiftModel?> getActive() async {
    final response = await _client.get(
      _uri('shifts/active'),
      headers: await _authorizedHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwResponseError(response);
    }

    if (response.body.trim().isEmpty) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('Respons shift aktif tidak valid.');
    }
    if (decoded == null) return null;
    if (decoded is Map<String, dynamic>) {
      return ActiveShiftModel.fromJson(decoded);
    }
    throw const ApiException('Respons shift aktif tidak valid.');
  }

  Future<CashAvailabilityModel> getCashAvailability() async {
    final response = await _client.get(
      _uri('balances/cash-availability'),
      headers: await _authorizedHeaders(),
    );
    return CashAvailabilityModel.fromJson(_decodeObject(response));
  }

  Future<void> openShift({
    required num startingCash,
    required String pin,
  }) async {
    final response = await _client.post(
      _uri('shifts/open'),
      headers: await _authorizedHeaders(),
      body: jsonEncode({'starting_cash': startingCash, 'pin': pin}),
    );
    _decodeObject(response);
  }

  Future<ActiveShiftModel> closeShift({
    required String shiftId,
    required num actualCash,
    String? pin,
    String? notes,
  }) async {
    final body = <String, Object>{
      'actual_cash': actualCash,
      if (pin != null && pin.isNotEmpty) 'pin': pin,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
    final response = await _client.post(
      _uri('shifts/$shiftId/close'),
      headers: await _authorizedHeaders(),
      body: jsonEncode(body),
    );
    return ActiveShiftModel.fromJson(_decodeObject(response));
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
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = _decodeResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Respons server tidak valid.');
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

  Never _throwResponseError(http.Response response) {
    _decodeResponse(response);
    throw const ApiException('Permintaan shift gagal.');
  }
}
