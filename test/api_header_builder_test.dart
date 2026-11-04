import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_header_builder.dart';

void main() {
  test('builds a bearer Authorization header from the provided token', () {
    expect(
      buildAuthorizationHeaders('jwt-token'),
      {'Authorization': 'Bearer jwt-token'},
    );
  });

  test('rejects a missing or empty token with the existing error message', () {
    expect(
      () => buildAuthorizationHeaders(null),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Sesi login tidak ditemukan. Silakan masuk lagi.',
        ),
      ),
    );
    expect(
      () => buildAuthorizationHeaders(''),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Sesi login tidak ditemukan. Silakan masuk lagi.',
        ),
      ),
    );
  });
}
