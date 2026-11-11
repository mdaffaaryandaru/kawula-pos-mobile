// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/shifts/data/models/active_shift_model.dart';
import 'package:kawula_pos/features/shifts/domain/entities/admin_shift_detail.dart';
import 'package:kawula_pos/features/transactions/data/models/checkout_models.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

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
    final decoded = decodeApiResponse(
      response,
      invalidResponseMessage: 'Respons shift aktif tidak valid.',
      allowEmptySuccess: true,
      allowErrorMessageLists: true,
      emptyErrorMessageUsesFallback: true,
    );
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

  Uri _uri(String path) => buildApiUri(_baseUrl, path);

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    return {
      ...buildAuthorizationHeaders(token),
      'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = _decodeResponse(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Respons server tidak valid.');
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
