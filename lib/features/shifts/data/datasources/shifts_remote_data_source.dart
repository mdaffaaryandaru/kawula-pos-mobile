import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../../../transactions/data/models/checkout_models.dart';
import '../../domain/entities/admin_shift_detail.dart';
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

  Future<List<ActiveShiftModel>> getShifts({String? status}) async {
    final uri = _uri('shifts');
    final response = await _client.get(
      status == null ? uri : uri.replace(queryParameters: {'status': status}),
      headers: await _authorizedHeaders(),
    );
    final body = _decodeResponse(response);
    if (body is! List) {
      throw const ApiException('Respons daftar shift tidak valid.');
    }
    return body
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data shift dari server tidak valid.');
          }
          return ActiveShiftModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<AdminShiftDetail> getShiftDetail(String shiftId) async {
    final body = _decodeObject(
      await _client.get(
        _uri('shifts/$shiftId'),
        headers: await _authorizedHeaders(),
      ),
    );
    final shift = body['shift'];
    final transactions = body['transactions'];
    if (shift is! Map<String, dynamic> || transactions is! List) {
      throw const ApiException('Respons detail shift tidak valid.');
    }
    return AdminShiftDetail(
      shift: ActiveShiftModel.fromJson(shift),
      transactions: transactions
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const ApiException(
                'Data transaksi pada detail shift tidak valid.',
              );
            }
            return TransactionRecordModel.fromJson(item);
          })
          .toList(growable: false),
    );
  }

  Future<ActiveShiftModel> forceCloseShift({
    required String shiftId,
    required num actualCash,
    required String notes,
  }) async {
    final response = await _client.post(
      _uri('shifts/$shiftId/force-close'),
      headers: await _authorizedHeaders(),
      body: jsonEncode({
        'actual_cash': actualCash,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );
    return ActiveShiftModel.fromJson(_decodeObject(response));
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
