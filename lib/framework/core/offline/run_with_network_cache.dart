import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

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
  } on SocketException {
    onNetworkFailure?.call();
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  } on TimeoutException {
    onNetworkFailure?.call();
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  } on HandshakeException {
    onNetworkFailure?.call();
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  }
}
