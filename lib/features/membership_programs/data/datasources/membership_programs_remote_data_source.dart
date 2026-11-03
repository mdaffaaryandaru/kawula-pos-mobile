// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/membership_programs/data/models/membership_program_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';

class MembershipProgramsRemoteDataSource {
  MembershipProgramsRemoteDataSource(
    this._client,
    this._baseUrl,
    this._readToken,
  );

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<MembershipProgramModel> getCurrentProgram() async {
    final response = await _client.get(
      _uri('membership-programs/current'),
      headers: await _authorizedHeaders(),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons program membership tidak valid.');
    }
    return MembershipProgramModel.fromJson(decoded);
  }

  Future<MembershipProgramModel> updateCurrentProgram({
    required int targetVisits,
    required String rewardType,
    required String? rewardId,
    required bool isActive,
  }) async {
    final response = await _client.patch(
      _uri('membership-programs'),
      headers: await _authorizedJsonHeaders(),
      body: jsonEncode({
        'target_visits': targetVisits,
        'reward_type': rewardType,
        'reward_product_id': rewardType == 'product' ? rewardId : null,
        'reward_discount_id': rewardType == 'discount' ? rewardId : null,
        'is_active': isActive,
      }),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'Respons server program membership tidak valid.',
      );
    }
    return MembershipProgramModel.fromJson(decoded);
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

  Object? _decodeResponse(http.Response response) {
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
      throw ApiException(
        message is String
            ? message
            : 'Permintaan gagal dengan kode ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
