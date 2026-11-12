import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/auth_session_expiry_handler.dart';
import 'package:kawula_pos/framework/core/network/http_client_factory.dart';
import 'package:kawula_pos/framework/core/network/session_aware_http_client.dart';
import 'package:kawula_pos/framework/core/network/timeout_http_client.dart';
import 'package:kawula_pos/framework/core/offline/run_with_network_cache.dart';

typedef _SendHandler = Future<http.StreamedResponse> Function(
  http.BaseRequest request,
);

class _FunctionClient extends http.BaseClient {
  _FunctionClient(this._handler);

  final _SendHandler _handler;
  int sendCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    sendCount++;
    return _handler(request);
  }
}

void main() {
  final uri = Uri.parse('https://example.test/transactions');

  test('unknown write outcome exposes only the safe message', () {
    final exception = RequestOutcomeUnknownException(
      uri,
      cause: StateError('request https://internal.example.test:8443/private'),
    );
    const safeMessage =
        'Status transaksi belum dapat dipastikan. Periksa riwayat server '
        'sebelum mencoba kembali.';

    expect(exception.message, safeMessage);
    expect(exception.toString(), safeMessage);
    expect(exception.toString(), isNot(contains(uri.toString())));
    expect(exception.toString(), isNot(contains('internal.example.test')));
    expect(exception.toString(), isNot(contains('8443')));
  });

  test('native client uses a 15-second configurable connection timeout', () {
    final defaultClient = createNativeHttpClient();
    final configuredClient = createNativeHttpClient(
      connectionTimeout: const Duration(seconds: 7),
    );
    addTearDown(() {
      defaultClient.close(force: true);
      configuredClient.close(force: true);
    });

    expect(defaultClient.connectionTimeout, const Duration(seconds: 15));
    expect(configuredClient.connectionTimeout, const Duration(seconds: 7));
  });

  test('GET times out while waiting for response headers', () async {
    final inner = _FunctionClient(
      (_) => Completer<http.StreamedResponse>().future,
    );
    final client = TimeoutHttpClient(
      inner,
      readResponseTimeout: const Duration(milliseconds: 10),
    );
    addTearDown(client.close);

    await expectLater(
      client.get(uri),
      throwsA(isA<NetworkResponseTimeoutException>()),
    );
  });

  test('GET times out when response body stops producing data', () async {
    var bodyCancelled = false;
    final body = StreamController<List<int>>(
      onCancel: () => bodyCancelled = true,
    );
    final inner = _FunctionClient(
      (_) async => http.StreamedResponse(body.stream, 200),
    );
    final client = TimeoutHttpClient(
      inner,
      readResponseTimeout: const Duration(milliseconds: 10),
    );
    addTearDown(() async {
      client.close();
      await body.close();
    });

    await expectLater(
      client.get(uri),
      throwsA(isA<NetworkResponseTimeoutException>()),
    );
    expect(bodyCancelled, isTrue);
  });

  test(
    'write response timeout is unknown and never retries the request',
    () async {
      final inner = _FunctionClient(
        (_) => Completer<http.StreamedResponse>().future,
      );
      final client = TimeoutHttpClient(
        inner,
        writeResponseTimeout: const Duration(milliseconds: 10),
      );
      addTearDown(client.close);

      await expectLater(
        client.post(uri, body: '{}'),
        throwsA(
          isA<RequestOutcomeUnknownException>().having(
            (error) => error.message,
            'message',
            contains(
              'Status transaksi belum dapat dipastikan. Periksa riwayat server',
            ),
          ),
        ),
      );
      expect(inner.sendCount, 1);
    },
  );

  test('write response body timeout is also an unknown outcome', () async {
    final body = StreamController<List<int>>();
    final inner = _FunctionClient(
      (_) async => http.StreamedResponse(body.stream, 201),
    );
    final client = TimeoutHttpClient(
      inner,
      writeResponseTimeout: const Duration(milliseconds: 10),
    );
    addTearDown(() async {
      client.close();
      await body.close();
    });

    await expectLater(
      client.patch(uri, body: '{}'),
      throwsA(isA<RequestOutcomeUnknownException>()),
    );
    expect(inner.sendCount, 1);
  });

  test('DELETE timeout does not retry the mutation', () async {
    final inner = _FunctionClient(
      (_) => Completer<http.StreamedResponse>().future,
    );
    final client = TimeoutHttpClient(
      inner,
      writeResponseTimeout: const Duration(milliseconds: 10),
    );
    addTearDown(client.close);

    await expectLater(
      client.delete(uri),
      throwsA(isA<RequestOutcomeUnknownException>()),
    );
    expect(inner.sendCount, 1);
  });

  test(
    'SessionAwareHttpClient sends through one shared timeout client',
    () async {
      final inner = _FunctionClient(
        (_) async => http.StreamedResponse(Stream.value([123, 125]), 200),
      );
      final sharedClient = SessionAwareHttpClient(
        TimeoutHttpClient(inner),
        AuthSessionExpiryHandler(),
      );
      addTearDown(sharedClient.close);

      await sharedClient.get(uri);
      await sharedClient.get(uri);

      expect(inner.sendCount, 2);
    },
  );

  test('GET response timeout is eligible for cache fallback', () async {
    var networkFailureNotified = false;
    final cached = await runWithNetworkCache<String>(
      request: () async {
        throw NetworkResponseTimeoutException(uri, const Duration(seconds: 10));
      },
      readCache: () async => 'cached',
      onNetworkFailure: () => networkFailureNotified = true,
    );

    expect(cached, 'cached');
    expect(networkFailureNotified, isTrue);
  });

  test('HTTP 400, 401 and 403 do not use cache fallback', () async {
    for (final status in [400, 401, 403]) {
      var cacheRead = false;
      await expectLater(
        runWithNetworkCache<String>(
          request: () async =>
              throw ApiException('HTTP $status', statusCode: status),
          readCache: () async {
            cacheRead = true;
            return 'cached';
          },
        ),
        throwsA(isA<ApiException>()),
      );
      expect(cacheRead, isFalse);
    }
  });

  test(
    'unknown write outcomes are never replaced with cached success',
    () async {
      var cacheRead = false;
      await expectLater(
        runWithNetworkCache<String>(
          request: () async => throw RequestOutcomeUnknownException(uri),
          readCache: () async {
            cacheRead = true;
            return 'cached';
          },
        ),
        throwsA(isA<RequestOutcomeUnknownException>()),
      );
      expect(cacheRead, isFalse);
    },
  );
}
