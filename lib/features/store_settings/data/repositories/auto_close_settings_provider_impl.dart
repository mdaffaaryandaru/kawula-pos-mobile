import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:kawula_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/auto_close_settings_provider.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/platform_network_exception.dart';
import 'package:kawula_pos/features/offline/data/cache/offline_master_data_cache.dart';

class AutoCloseSettingsProviderImpl implements AutoCloseSettingsProvider {
  const AutoCloseSettingsProviderImpl({
    required this.repository,
    required this.masterDataCache,
  });

  final StoreSettingsRepository? repository;
  final OfflineMasterDataCache? masterDataCache;

  @override
  Future<AutoCloseSettingsResult> getAutoCloseSettings({
    required String role,
    required String userId,
    required String? outletId,
  }) async {
    final scopedCache = masterDataCache?.forRole(
      role: role,
      userId: userId,
      outletId: outletId,
    );

    if (scopedCache?.shouldUseOfflineData == true) {
      return _loadCachedSettings(scopedCache);
    }

    final settingsRepository = repository;
    if (settingsRepository == null) {
      return _loadCachedSettings(
        scopedCache,
        unavailableReason: 'Repository pengaturan shift tidak tersedia.',
      );
    }

    try {
      final settings = await settingsRepository.getSettings();
      String? cacheError;
      if (scopedCache != null && scopedCache.isScoped) {
        try {
          await scopedCache.save(
            cacheType: 'cashier_store_settings',
            dataKey: 'store_settings',
            payload: StoreSettingsModel.fromEntity(settings).toJson(),
          );
        } on Exception catch (error) {
          cacheError = 'Cache pengaturan auto-close gagal disimpan: $error';
        }
      }
      return AutoCloseSettingsResult(
        settings: settings,
        errorMessage: cacheError,
      );
    } on http.ClientException catch (error) {
      scopedCache?.markOffline();
      return _loadCachedSettings(
        scopedCache,
        unavailableReason: error.toString(),
      );
    } on TimeoutException catch (error) {
      scopedCache?.markOffline();
      return _loadCachedSettings(
        scopedCache,
        unavailableReason: error.toString(),
      );
    } on ApiException catch (error) {
      return AutoCloseSettingsResult(errorMessage: error.message);
    } on FormatException catch (error) {
      return AutoCloseSettingsResult(errorMessage: error.message);
    } on Exception catch (error) {
      if (isPlatformNetworkException(error)) {
        scopedCache?.markOffline();
        return _loadCachedSettings(
          scopedCache,
          unavailableReason: error.toString(),
        );
      }
      return AutoCloseSettingsResult(
        errorMessage: 'Pengaturan auto-close tidak dapat dimuat: $error',
      );
    }
  }

  Future<AutoCloseSettingsResult> _loadCachedSettings(
    OfflineMasterDataCache? cache, {
    String? unavailableReason,
  }) async {
    if (cache == null || !cache.isScoped) {
      return AutoCloseSettingsResult(
        errorMessage:
            unavailableReason ?? 'Pengaturan auto-close belum tersedia.',
      );
    }

    final Object? payload;
    try {
      payload = await cache.read(
        cacheType: 'cashier_store_settings',
        dataKey: 'store_settings',
      );
    } on Exception catch (error) {
      return AutoCloseSettingsResult(
        errorMessage: 'Cache pengaturan auto-close gagal dibaca: $error',
      );
    }

    if (payload is! Map) {
      return AutoCloseSettingsResult(
        isEstimated: true,
        errorMessage:
            unavailableReason ?? 'Pengaturan auto-close belum memiliki cache.',
      );
    }

    try {
      final settings = StoreSettingsModel.fromJson(
        Map<String, dynamic>.from(payload),
      );
      return AutoCloseSettingsResult(settings: settings, isEstimated: true);
    } on FormatException catch (error) {
      return AutoCloseSettingsResult(
        isEstimated: true,
        errorMessage: error.message,
      );
    }
  }
}
