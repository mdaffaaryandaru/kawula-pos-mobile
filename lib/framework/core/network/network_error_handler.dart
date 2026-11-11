import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/platform_network_exception.dart';
import 'package:kawula_pos/framework/core/network/timeout_http_client.dart';

enum NetworkErrorKind {
  requestOutcomeUnknown,
  responseTimeout,
  timeout,
  platformNetwork,
  clientFailure,
  httpResponse,
  other,
}

NetworkErrorKind classifyNetworkError(Object error) {
  if (error is RequestOutcomeUnknownException) {
    return NetworkErrorKind.requestOutcomeUnknown;
  }
  if (error is NetworkResponseTimeoutException) {
    return NetworkErrorKind.responseTimeout;
  }
  if (error is TimeoutException) return NetworkErrorKind.timeout;
  if (isPlatformNetworkException(error)) {
    return NetworkErrorKind.platformNetwork;
  }
  if (error is http.ClientException) return NetworkErrorKind.clientFailure;
  if (error is ApiException) return NetworkErrorKind.httpResponse;
  return NetworkErrorKind.other;
}

bool canUseCacheForNetworkError(Object error, {required bool readOnlyRequest}) {
  return switch (classifyNetworkError(error)) {
    NetworkErrorKind.responseTimeout ||
    NetworkErrorKind.timeout ||
    NetworkErrorKind.platformNetwork => true,
    NetworkErrorKind.clientFailure => readOnlyRequest,
    NetworkErrorKind.requestOutcomeUnknown ||
    NetworkErrorKind.httpResponse ||
    NetworkErrorKind.other => false,
  };
}
