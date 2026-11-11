import 'dart:io';

bool isPlatformNetworkException(Object error) =>
    error is SocketException || error is HandshakeException;
