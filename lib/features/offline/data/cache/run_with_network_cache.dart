import 'package:kawula_pos/framework/core/network/network_error_handler.dart';

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
  } on Exception catch (error) {
    if (!canUseCacheForNetworkError(error, readOnlyRequest: true)) rethrow;
    onNetworkFailure?.call();
    final cached = await readCache();
    if (cached != null) return cached;
    rethrow;
  }
}
