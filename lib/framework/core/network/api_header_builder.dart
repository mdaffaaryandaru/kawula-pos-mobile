import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';

Map<String, String> buildAuthorizationHeaders(String? token) {
  if (token == null || token.isEmpty) {
    throw const ApiException(
      'Sesi login tidak ditemukan. Silakan masuk lagi.',
    );
  }
  return {'Authorization': 'Bearer $token'};
}
