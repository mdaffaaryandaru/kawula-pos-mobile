import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<T> runWithNetworkCache<T>({
  required Future<T> Function() request,
  required Future<T?> Function() readCache,
}) async {
  try {
    return await request();
  } on http.ClientException {
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  } on SocketException {
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  } on TimeoutException {
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  } on HandshakeException {
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  }
}
