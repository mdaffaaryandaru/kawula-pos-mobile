import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static const _dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_dartDefineBaseUrl.isNotEmpty) return _dartDefineBaseUrl;

    final platformKey = kIsWeb
        ? 'API_BASE_URL_WEB'
        : defaultTargetPlatform == TargetPlatform.android
        ? 'API_BASE_URL_ANDROID'
        : 'API_BASE_URL_DEFAULT';
    return dotenv.env[platformKey] ??
        dotenv.env['API_BASE_URL'] ??
        'http://localhost:3001/api';
  }
}
