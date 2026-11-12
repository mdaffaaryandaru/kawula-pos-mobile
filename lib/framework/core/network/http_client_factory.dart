import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

HttpClient createNativeHttpClient({
  Duration connectionTimeout = const Duration(seconds: 15),
}) => HttpClient()..connectionTimeout = connectionTimeout;

http.Client createPlatformHttpClient({
  Duration connectionTimeout = const Duration(seconds: 15),
}) => IOClient(createNativeHttpClient(connectionTimeout: connectionTimeout));
