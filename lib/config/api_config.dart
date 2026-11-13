import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static const productionBaseUrl = 'https://kawula-api.ignisys.site/api';
  static const androidEmulatorBaseUrl = 'https://kawula-api.ignisys.site/api';
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
    final override = dartDefineBaseUrl.trim();
    if (override.isNotEmpty) return override;

    final platformKey = switch (platform) {
      TargetPlatform.android => 'API_BASE_URL_ANDROID',
      TargetPlatform.iOS => 'API_BASE_URL_IOS',
      _ => 'API_BASE_URL_DEFAULT',
    };
    return environment[platformKey] ??
        environment['API_BASE_URL'] ??
        productionBaseUrl;
  }
}
