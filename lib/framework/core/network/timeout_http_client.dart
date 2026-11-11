import 'dart:async';

import 'package:http/http.dart' as http;

class NetworkResponseTimeoutException extends TimeoutException {
  NetworkResponseTimeoutException(this.uri, Duration timeout)
    : super('Menunggu respons jaringan melewati batas waktu.', timeout);

  final Uri uri;
}

class RequestOutcomeUnknownException extends http.ClientException {
  RequestOutcomeUnknownException(Uri uri, {Object? cause})
    : super(
        'Status transaksi belum dapat dipastikan. Periksa riwayat server '
        'sebelum mencoba kembali.',
        uri,
      );

  @override
  String toString() => message;
}

class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient(
    this._inner, {
    this.readResponseTimeout = const Duration(seconds: 10),
    this.writeResponseTimeout = const Duration(seconds: 45),
  });

  final http.Client _inner;
  final Duration readResponseTimeout;
  final Duration writeResponseTimeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isRead = request.method.toUpperCase() == 'GET';
    final timeout = isRead ? readResponseTimeout : writeResponseTimeout;
    final http.StreamedResponse response;
    try {
      response = await _inner.send(request).timeout(timeout);
    } on TimeoutException {
      if (isRead) {
        throw NetworkResponseTimeoutException(request.url, timeout);
      }
      throw RequestOutcomeUnknownException(request.url);
    } on http.ClientException catch (error) {
      if (isRead) rethrow;
      throw RequestOutcomeUnknownException(request.url, cause: error);
    } on Exception catch (error) {
      if (isRead) rethrow;
      throw RequestOutcomeUnknownException(request.url, cause: error);
    }

    final responseStream = response.stream.timeout(
      timeout,
      onTimeout: (sink) {
        if (isRead) {
          sink.addError(NetworkResponseTimeoutException(request.url, timeout));
        } else {
          sink.addError(RequestOutcomeUnknownException(request.url));
        }
      },
    );
    return http.StreamedResponse(
      isRead
          ? responseStream
          : responseStream.transform(
              StreamTransformer<List<int>, List<int>>.fromHandlers(
                handleError: (error, stackTrace, sink) {
                  if (error is RequestOutcomeUnknownException) {
                    sink.addError(error, stackTrace);
                  } else {
                    sink.addError(
                      RequestOutcomeUnknownException(request.url, cause: error),
                      stackTrace,
                    );
                  }
                },
              ),
            ),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
