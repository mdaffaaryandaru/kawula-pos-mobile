import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/network_error_handler.dart';
import 'package:kawula_pos/framework/core/network/timeout_http_client.dart';

void main() {
  test('classifies timeout, socket, TLS, and response timeout errors', () {
    expect(
      classifyNetworkError(TimeoutException('timed out')),
      NetworkErrorKind.timeout,
    );
    expect(
      classifyNetworkError(
        NetworkResponseTimeoutException(
          Uri.https('example.test', '/'),
          const Duration(seconds: 10),
        ),
      ),
      NetworkErrorKind.responseTimeout,
    );
    expect(
      classifyNetworkError(const SocketException('offline')),
      NetworkErrorKind.platformNetwork,
    );
    expect(
      classifyNetworkError(const HandshakeException('TLS failed')),
      NetworkErrorKind.platformNetwork,
    );
  });

  test(
    'keeps unknown write outcomes distinct from ordinary client failures',
    () {
      final unknown = RequestOutcomeUnknownException(
        Uri.https('example.test', '/transactions'),
      );
      final clientFailure = http.ClientException('connection failed');

      expect(
        classifyNetworkError(unknown),
        NetworkErrorKind.requestOutcomeUnknown,
      );
      expect(
        classifyNetworkError(clientFailure),
        NetworkErrorKind.clientFailure,
      );
      expect(
        canUseCacheForNetworkError(unknown, readOnlyRequest: true),
        isFalse,
      );
      expect(
        canUseCacheForNetworkError(clientFailure, readOnlyRequest: true),
        isTrue,
      );
      expect(
        canUseCacheForNetworkError(clientFailure, readOnlyRequest: false),
        isFalse,
      );
    },
  );

  test('HTTP response errors are not cache fallback candidates', () {
    for (final status in [400, 401, 403, 404, 422, 500]) {
      final error = ApiException('HTTP $status', statusCode: status);
      expect(classifyNetworkError(error), NetworkErrorKind.httpResponse);
      expect(canUseCacheForNetworkError(error, readOnlyRequest: true), isFalse);
    }
  });
}
