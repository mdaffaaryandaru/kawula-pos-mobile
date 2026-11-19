import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static const _dartDefineBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => resolveBaseUrl(
    platform: defaultTargetPlatform,
    environment: dotenv.env,
    dartDefineBaseUrl: _dartDefineBaseUrl,
  );

  @visibleForTesting
  static String resolveBaseUrl({
    required TargetPlatform platform,
    required Map<String, String> environment,
    String dartDefineBaseUrl = '',
  }) {
    // prioritas pertama : Dart define
    final override = dartDefineBaseUrl.trim();
    if (override.isNotEmpty) return override;

    //prioritas kedua : konfigurasi env sesuai platform

    final platformKey = switch (platform) {
      TargetPlatform.android => 'API_BASE_URL_ANDROID',
      TargetPlatform.iOS => 'API_BASE_URL_IOS',
      _ => 'API_BASE_URL_DEFAULT',
    };

    final platformUrl = environment[platformKey]?.trim();
    if (platformUrl != null && platformUrl.isNotEmpty) {
      return platformUrl;
    }
    //prioritas ketiga : konfigurasi URL umum
    final defaultUrl = environment['API_BASE_URL_DEFAULT']?.trim();
    if (defaultUrl != null && defaultUrl.isNotEmpty) {
      return defaultUrl;
    }

    throw Exception('Base URL belum di konfigurasi. periksa file .env');
  }
}
