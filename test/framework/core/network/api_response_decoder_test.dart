import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/api_response_decoder.dart';

void main() {
  test('decodes successful JSON without imposing an endpoint shape', () {
    final list = decodeApiResponse(http.Response('[1, 2]', 200));
    final object = decodeApiResponse(http.Response('{"data":true}', 200));

    expect(list, [1, 2]);
    expect(object, {'data': true});
  });

  test('treats a whitespace-only success body as empty by default', () {
    expect(decodeApiResponse(http.Response('  \n ', 204)), isNull);
  });

  test('allows endpoint-specific strict whitespace handling', () {
    expect(
      () =>
          decodeApiResponse(http.Response('  \n ', 200), trimEmptyBody: false),
      throwsA(isA<ApiException>()),
    );
    expect(
      decodeApiResponse(http.Response('', 200), trimEmptyBody: false),
      isNull,
    );
  });

  test('reports invalid successful JSON with the configured message', () {
    expect(
      () => decodeApiResponse(
        http.Response('<html>', 200),
        invalidResponseMessage: 'Respons produk tidak valid.',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Respons produk tidak valid.',
        ),
      ),
    );
  });

  test('extracts map, string, list and nested error messages', () {
    expect(
      () => decodeApiResponse(http.Response('{"message":"Ditolak"}', 400)),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Ditolak',
        ),
      ),
    );
    expect(
      () => decodeApiResponse(
        http.Response('["Salah satu", "Kesalahan lain"]', 422),
        allowErrorMessageLists: true,
        allowTopLevelErrorLists: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Salah satu\nKesalahan lain',
        ),
      ),
    );
    expect(
      () => decodeApiResponse(
        http.Response('{"message":["Pertama","Kedua"]}', 422),
        allowErrorMessageLists: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Pertama\nKedua',
        ),
      ),
    );
    expect(
      () => decodeApiResponse(
        http.Response('{"message":{"message":"Nested error"}}', 400),
        allowNestedErrorMessage: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Nested error',
        ),
      ),
    );
    expect(
      () => decodeApiResponse(
        http.Response('"Plain JSON error"', 400),
        allowStringErrorBody: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Plain JSON error',
        ),
      ),
    );
    expect(
      () => decodeApiResponse(
        http.Response('Plain text error', 400),
        allowStringErrorBody: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Plain text error',
        ),
      ),
    );
  });

  test('preserves HTTP status and an optional endpoint prefix', () {
    for (final status in [400, 422, 401, 403]) {
      try {
        decodeApiResponse(
          http.Response('{"message":"Access denied"}', status),
          errorPrefix: 'GET /api/outlets',
        );
        fail('Expected status $status to throw ApiException.');
      } on ApiException catch (error) {
        expect(error.statusCode, status);
        expect(error.message, 'GET /api/outlets: Access denied');
      }
    }
  });

  test('does not replace empty HTTP error with a successful null result', () {
    expect(
      () => decodeApiResponse(http.Response('', 403)),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.message,
              'message',
              'Permintaan gagal dengan kode 403.',
            ),
      ),
    );
  });

  test('keeps top-level error lists opt-in', () {
    expect(
      () => decodeApiResponse(
        http.Response('["one", "two"]', 422),
        allowErrorMessageLists: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Permintaan gagal dengan kode 422.',
        ),
      ),
    );
  });

  test('preserves strict empty-body and empty-message policies by option', () {
    expect(
      () => decodeApiResponse(http.Response('', 200), allowEmptySuccess: false),
      throwsA(isA<ApiException>()),
    );
    expect(
      () => decodeApiResponse(
        http.Response('{"message":""}', 400),
        allowEmptySuccess: false,
      ),
      throwsA(
        isA<ApiException>().having((error) => error.message, 'message', ''),
      ),
    );
    expect(
      () => decodeApiResponse(
        http.Response('{"message":""}', 400),
        allowErrorMessageLists: true,
        emptyErrorMessageUsesFallback: true,
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Permintaan gagal dengan kode 400.',
        ),
      ),
    );
  });
}
