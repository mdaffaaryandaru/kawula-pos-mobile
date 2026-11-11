// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/members/data/models/member_model.dart';
import 'package:kawula_pos/features/members/data/models/member_reward_claim_model.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';
import 'package:kawula_pos/framework/core/network/api_url_builder.dart';

class MembersRemoteDataSource {
  MembersRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<MemberModel>> searchMembers(String search) =>
      getMembers(search: search);

  Future<List<MemberModel>> getMembers({String? search}) async {
    final uri = _uri('members');
    final requestUri = search == null || search.isEmpty
        ? uri
        : uri.replace(queryParameters: {'search': search});
    final response = await _client.get(
      requestUri,
      headers: await _authorizedHeaders(),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw const ApiException('Respons daftar member tidak valid.');
    }
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Data member dari server tidak valid.');
          }
          return MemberModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<MemberModel> createMember({
    required String name,
    required String phoneNumber,
    required String email,
  }) async {
    final response = await _client.post(
      _uri('members'),
      headers: await _authorizedJsonHeaders(),
      body: jsonEncode({
        'name': name.trim(),
        'phone_number': phoneNumber.trim(),
        'email': email.trim(),
      }),
    );
    return _memberFromResponse(response);
  }

  Future<MemberModel> updateMember({
    required String memberId,
    required String name,
    required String phoneNumber,
    required String email,
    required bool isActive,
  }) async {
    final response = await _client.patch(
      _uri('members/$memberId'),
      headers: await _authorizedJsonHeaders(),
      body: jsonEncode({
        'name': name.trim(),
        'phone_number': phoneNumber.trim(),
        'email': email.trim(),
        'is_active': isActive,
      }),
    );
    return _memberFromResponse(response);
  }

  Future<void> deleteMember(String memberId) async {
    final response = await _client.delete(
      _uri('members/$memberId'),
      headers: await _authorizedHeaders(),
    );
    _decodeResponse(response);
  }

  Future<MemberRewardClaimModel> claimReward(String memberId) async {
    final response = await _client.post(
      _uri('members/$memberId/claim-reward'),
      headers: await _authorizedHeaders(),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons klaim reward member tidak valid.');
    }
    return MemberRewardClaimModel.fromJson(decoded);
  }

  Future<MemberModel> _memberFromResponse(http.Response response) async {
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons server member tidak valid.');
    }
    return MemberModel.fromJson(decoded);
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

  Object? _decodeResponse(http.Response response) {
    return decodeApiResponse(response);
  }
}
