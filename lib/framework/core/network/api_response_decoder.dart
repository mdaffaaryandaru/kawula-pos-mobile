import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';

Object? decodeApiResponse(
  http.Response response, {
  String invalidResponseMessage = 'Respons server tidak valid.',
  String? errorPrefix,
  bool allowEmptySuccess = true,
  bool trimEmptyBody = true,
  bool allowErrorMessageLists = false,
  bool allowTopLevelErrorLists = false,
  bool allowStringErrorBody = false,
  bool allowNestedErrorMessage = false,
  bool emptyErrorMessageUsesFallback = false,
}) {
  final body = response.body;
  final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
  Object? decoded;
  final isEmptyBody = trimEmptyBody ? body.trim().isEmpty : body.isEmpty;
  if (allowEmptySuccess && isEmptyBody) {
    decoded = null;
  } else {
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      if (!isSuccess) {
        throw _httpError(
          response.statusCode,
          errorPrefix: errorPrefix,
          message: allowStringErrorBody ? body.trim() : null,
          emptyMessageUsesFallback: emptyErrorMessageUsesFallback,
        );
      }
      throw ApiException(invalidResponseMessage);
    }
  }

  if (!isSuccess) {
    final message = _errorMessage(
      decoded,
      allowLists: allowErrorMessageLists,
      allowTopLevelLists: allowTopLevelErrorLists,
      allowStrings: allowStringErrorBody,
      allowNested: allowNestedErrorMessage,
      emptyMessageUsesFallback: emptyErrorMessageUsesFallback,
    );
    throw _httpError(
      response.statusCode,
      errorPrefix: errorPrefix,
      message: message,
      emptyMessageUsesFallback: emptyErrorMessageUsesFallback,
    );
  }
  return decoded;
}

ApiException _httpError(
  int statusCode, {
  required String? errorPrefix,
  required String? message,
  required bool emptyMessageUsesFallback,
}) {
  final fallback = 'Permintaan gagal dengan kode $statusCode.';
  final detail =
      message == null || (message.isEmpty && emptyMessageUsesFallback)
      ? fallback
      : message;
  return ApiException(
    errorPrefix == null ? detail : '$errorPrefix: $detail',
    statusCode: statusCode,
  );
}

String? _errorMessage(
  Object? decoded, {
  required bool allowLists,
  required bool allowTopLevelLists,
  required bool allowStrings,
  required bool allowNested,
  required bool emptyMessageUsesFallback,
}) {
  if (decoded is String) {
    return allowStrings && decoded.trim().isNotEmpty ? decoded : null;
  }
  if (decoded is List) {
    return allowTopLevelLists ? _joinMessages(decoded, allowNested) : null;
  }
  if (decoded is! Map) return null;

  final message = decoded['message'];
  if (message is String && (message.isNotEmpty || !emptyMessageUsesFallback)) {
    return message;
  }
  if (allowLists && message is List) {
    return _joinMessages(message, allowNested);
  }
  if (allowNested && message is Map) {
    return _errorMessage(
      message,
      allowLists: allowLists,
      allowTopLevelLists: allowTopLevelLists,
      allowStrings: allowStrings,
      allowNested: true,
      emptyMessageUsesFallback: emptyMessageUsesFallback,
    );
  }
  return null;
}

String? _joinMessages(List values, bool allowNested) {
  final messages = values
      .map((value) {
        if (value is String) return value;
        if (allowNested && value is Map) {
          return _errorMessage(
            value,
            allowLists: true,
            allowTopLevelLists: false,
            allowStrings: true,
            allowNested: true,
            emptyMessageUsesFallback: false,
          );
        }
        return null;
      })
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  return messages.isEmpty ? null : messages.join('\n');
}
