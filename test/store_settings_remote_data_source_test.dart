import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kawula_pos/features/store_settings/data/datasources/store_settings_remote_data_source.dart';
import 'package:kawula_pos/features/store_settings/data/models/store_settings_model.dart';

void main() {
  const baseUrl = 'http://localhost:3001/api';
  const settingsJson = {
    'store_name': 'Kawula Cafe',
    'address': 'Jl. Kopi',
    'logo_url': '/uploads/store/logo.png',
    'tax_percentage': 10,
    'service_charge': 2500,
    'auto_close_shift_enabled': true,
    'auto_close_shift_time': '23:30',
  };

  test('loads and updates settings using the backend contract', () async {
    final client = MockClient((request) async {
      expect(request.url, Uri.parse('$baseUrl/store-settings'));
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      if (request.method == 'GET') {
        return http.Response(jsonEncode(settingsJson), 200);
      }

      expect(request.method, 'PATCH');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['store_name'], 'Kawula Updated');
      expect(body['logo_url'], '/uploads/store/new-logo.png');
      expect(body['tax_percentage'], 11);
      expect(body['service_charge'], 3000);
      expect(body['auto_close_shift_enabled'], isFalse);
      expect(body['auto_close_shift_time'], '22:15');
      return http.Response(
        jsonEncode({...settingsJson, 'store_name': 'Kawula Updated'}),
        200,
      );
    });
    final dataSource = StoreSettingsRemoteDataSource(
      client,
      baseUrl,
      () async => 'jwt-token',
    );

    final loaded = await dataSource.getSettings();
    expect(loaded.storeName, 'Kawula Cafe');
    expect(loaded.autoCloseShiftTime, '23:30');
    final saved = await dataSource.updateSettings(
      const StoreSettingsModel(
        storeName: 'Kawula Updated',
        address: 'Jl. Kopi',
        logoUrl: '/uploads/store/new-logo.png',
        taxPercentage: 11,
        serviceCharge: 3000,
        autoCloseShiftEnabled: false,
        autoCloseShiftTime: '22:15',
      ),
    );
    expect(saved.storeName, 'Kawula Updated');
  });

  test(
    'uploads one logo using the backend multipart field and endpoint',
    () async {
      final client = MockClient((request) async {
        expect(request, isA<http.Request>());
        final multipartRequest = request;
        expect(multipartRequest.method, 'POST');
        expect(
          multipartRequest.url,
          Uri.parse('$baseUrl/store-settings/upload-logo'),
        );
        expect(multipartRequest.headers['Authorization'], 'Bearer jwt-token');
        expect(
          multipartRequest.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        expect(multipartRequest.body, contains('name="logo"'));
        expect(multipartRequest.body, contains('filename="store-logo.png"'));
        return http.Response(
          jsonEncode({'url': '/uploads/store/store-logo.png'}),
          201,
        );
      });
      final dataSource = StoreSettingsRemoteDataSource(
        client,
        baseUrl,
        () async => 'jwt-token',
      );
      final image = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'store-logo.png',
        mimeType: 'image/png',
      );

      final url = await dataSource.uploadLogo(image);

      expect(url, '/uploads/store/store-logo.png');
    },
  );
}
