import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/config/api_config.dart';

void main() {
  test(
    'uses the Dart define before platform or generic environment values',
    () {
      expect(
        ApiConfig.resolveBaseUrl(
          platform: TargetPlatform.android,
          environment: const {
            'API_BASE_URL_ANDROID': 'http://10.0.2.2:3001/api',
            'API_BASE_URL': 'https://generic.example/api',
          },
          dartDefineBaseUrl: 'https://override.example/api',
        ),
        'https://override.example/api',
      );
    },
  );

  test('uses Android environment override for emulator or physical device', () {
    expect(
      ApiConfig.resolveBaseUrl(
        platform: TargetPlatform.android,
        environment: const {
          'API_BASE_URL_ANDROID': 'http://10.0.2.2:3001/api',
          'API_BASE_URL': 'https://generic.example/api',
        },
      ),
      'http://10.0.2.2:3001/api',
    );
  });

  test('uses iOS or default environment configuration when applicable', () {
    expect(
      ApiConfig.resolveBaseUrl(
        platform: TargetPlatform.iOS,
        environment: const {
          'API_BASE_URL_IOS': 'https://ios.example/api',
          'API_BASE_URL_DEFAULT': 'https://default.example/api',
        },
      ),
      'https://ios.example/api',
    );
    expect(
      ApiConfig.resolveBaseUrl(
        platform: TargetPlatform.linux,
        environment: const {
          'API_BASE_URL_DEFAULT': 'https://default.example/api',
        },
      ),
      'https://default.example/api',
    );
  });

  test('defaults to production instead of localhost or emulator addresses', () {
    expect(
      ApiConfig.resolveBaseUrl(
        platform: TargetPlatform.android,
        environment: const {},
      ),
      ApiConfig.productionBaseUrl,
    );
    expect(ApiConfig.productionBaseUrl, 'https://kawula-api.ignisys.site/api');
  });
}
