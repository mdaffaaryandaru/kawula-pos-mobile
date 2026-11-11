import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:kawula_pos/framework/core/network/platform_network_exception.dart';

Future<T> runWithNetworkCache<T>({
  required Future<T> Function() request,
  required Future<T?> Function() readCache,
  bool skipRequest = false,
  void Function()? onNetworkFailure,
  void Function()? onRequestSuccess,
}) async {
  if (skipRequest) {
    final cached = await readCache();
    if (cached != null) return cached;
    throw StateError('Data belum tersedia di cache offline.');
  }
  try {
    final result = await request();
    onRequestSuccess?.call();
    return result;
  } on http.ClientException {
    onNetworkFailure?.call();
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  } on TimeoutException {
    onNetworkFailure?.call();
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  } on Exception catch (error) {
    if (!isPlatformNetworkException(error)) rethrow;
    onNetworkFailure?.call();
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  }
}
