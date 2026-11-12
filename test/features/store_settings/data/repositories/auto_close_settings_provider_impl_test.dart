import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:kawula_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:kawula_pos/features/store_settings/data/repositories/auto_close_settings_provider_impl.dart';
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/cached_records_dao.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/features/shared/domain/value_objects/image_upload_input.dart';

void main() {
  const settings = StoreSettings(
    storeName: 'Kawula Cafe',
    address: 'Jl. Kopi',
    logoUrl: '',
    taxPercentage: 10,
    serviceCharge: 0,
    autoCloseShiftEnabled: true,
    autoCloseShiftTime: '22:30',
  );
  const role = 'Kasir';
  const userId = 'cashier-1';
  const outletId = 'outlet-1';

  test('fetches online settings and saves scoped cache payload', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);
    final cache = OfflineMasterDataCache(database.cachedRecordsDao);
    final repository = _StoreSettingsRepository(() async => settings);
    final provider = AutoCloseSettingsProviderImpl(
      repository: repository,
      masterDataCache: cache,
    );

    final result = await provider.getAutoCloseSettings(
      role: role,
      userId: userId,
      outletId: outletId,
    );

    final scopedCache = cache.forRole(
      role: role,
      userId: userId,
      outletId: outletId,
    )!;
    _expectSettings(result.settings, settings);
    expect(result.isEstimated, isFalse);
    expect(result.errorMessage, isNull);
    expect(repository.getSettingsCalls, 1);
    expect(
      await scopedCache.read(
        cacheType: 'cashier_store_settings',
        dataKey: 'store_settings',
      ),
      StoreSettingsModel.fromEntity(settings).toJson(),
    );
  });

  test('uses scoped cache as estimated data while offline', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);
    final cache = OfflineMasterDataCache(database.cachedRecordsDao);
    await _saveScoped(cache, StoreSettingsModel.fromEntity(settings).toJson());
    cache.markOffline();
    final repository = _StoreSettingsRepository(
      () async => throw StateError('Server should not be requested'),
    );

    final result = await AutoCloseSettingsProviderImpl(
      repository: repository,
      masterDataCache: cache,
    ).getAutoCloseSettings(role: role, userId: userId, outletId: outletId);

    _expectSettings(result.settings, settings);
    expect(result.isEstimated, isTrue);
    expect(result.errorMessage, isNull);
    expect(repository.getSettingsCalls, 0);
  });

  test('marks cache offline and falls back after a network failure', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);
    final cache = OfflineMasterDataCache(database.cachedRecordsDao);
    await _saveScoped(cache, StoreSettingsModel.fromEntity(settings).toJson());
    final repository = _StoreSettingsRepository(
      () async => throw http.ClientException('network unavailable'),
    );

    final result = await AutoCloseSettingsProviderImpl(
      repository: repository,
      masterDataCache: cache,
    ).getAutoCloseSettings(role: role, userId: userId, outletId: outletId);

    _expectSettings(result.settings, settings);
    expect(result.isEstimated, isTrue);
    expect(cache.networkStatus, OfflineNetworkStatus.offline);
  });

  test('does not treat API errors as network failures', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);
    final cache = OfflineMasterDataCache(database.cachedRecordsDao);
    await _saveScoped(cache, StoreSettingsModel.fromEntity(settings).toJson());
    final repository = _StoreSettingsRepository(
      () async => throw const ApiException('Server rejected request.'),
    );

    final result = await AutoCloseSettingsProviderImpl(
      repository: repository,
      masterDataCache: cache,
    ).getAutoCloseSettings(role: role, userId: userId, outletId: outletId);

    expect(result.settings, isNull);
    expect(result.isEstimated, isFalse);
    expect(result.errorMessage, 'Server rejected request.');
    expect(cache.networkStatus, OfflineNetworkStatus.online);
  });

  test(
    'reports unavailable repository while still attempting cache read',
    () async {
      final database = AppDatabase(executor: NativeDatabase.memory());
      addTearDown(database.close);
      final cache = OfflineMasterDataCache(database.cachedRecordsDao);
      await _saveScoped(
        cache,
        StoreSettingsModel.fromEntity(settings).toJson(),
      );

      final result = await AutoCloseSettingsProviderImpl(
        repository: null,
        masterDataCache: cache,
      ).getAutoCloseSettings(role: role, userId: userId, outletId: outletId);

      _expectSettings(result.settings, settings);
      expect(result.isEstimated, isTrue);
      expect(result.errorMessage, isNull);
    },
  );

  test('reads the legacy scoped cache key for cashier settings', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);
    final cache = OfflineMasterDataCache(database.cachedRecordsDao);
    await database.cachedRecordsDao.saveCache(
      cacheType: 'cashier_store_settings',
      cacheKey: jsonEncode([userId, outletId, 'store_settings']),
      payload: StoreSettingsModel.fromEntity(settings).toJson(),
    );
    cache.markOffline();

    final result = await AutoCloseSettingsProviderImpl(
      repository: _StoreSettingsRepository(
        () async => throw StateError('Server should not be requested'),
      ),
      masterDataCache: cache,
    ).getAutoCloseSettings(role: role, userId: userId, outletId: outletId);

    _expectSettings(result.settings, settings);
    expect(result.isEstimated, isTrue);
  });

  test(
    'reports unavailable cache when neither repository nor cache exists',
    () async {
      final result = await AutoCloseSettingsProviderImpl(
        repository: null,
        masterDataCache: null,
      ).getAutoCloseSettings(role: role, userId: userId, outletId: outletId);

      expect(result.settings, isNull);
      expect(result.isEstimated, isFalse);
      expect(
        result.errorMessage,
        'Repository pengaturan shift tidak tersedia.',
      );
    },
  );

  test('reports malformed cached settings as estimated data failure', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);
    final cache = OfflineMasterDataCache(database.cachedRecordsDao);
    await _saveScoped(cache, {'auto_close_shift_time': 20});
    cache.markOffline();

    final result = await AutoCloseSettingsProviderImpl(
      repository: _StoreSettingsRepository(
        () async => throw StateError('Server should not be requested'),
      ),
      masterDataCache: cache,
    ).getAutoCloseSettings(role: role, userId: userId, outletId: outletId);

    expect(result.settings, isNull);
    expect(result.isEstimated, isTrue);
    expect(result.errorMessage, 'Data pengaturan toko tidak valid.');
  });

  test('keeps server settings when scoped cache save fails', () async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);
    final cache = OfflineMasterDataCache(_FailingCachedRecordsDao(database));
    final provider = AutoCloseSettingsProviderImpl(
      repository: _StoreSettingsRepository(() async => settings),
      masterDataCache: cache,
    );

    final result = await provider.getAutoCloseSettings(
      role: role,
      userId: userId,
      outletId: outletId,
    );

    expect(result.settings, settings);
    expect(result.isEstimated, isFalse);
    expect(
      result.errorMessage,
      startsWith('Cache pengaturan auto-close gagal disimpan:'),
    );
  });
}

Future<void> _saveScoped(OfflineMasterDataCache cache, Object? payload) async {
  final scopedCache = cache.forRole(
    role: 'Kasir',
    userId: 'cashier-1',
    outletId: 'outlet-1',
  )!;
  await scopedCache.save(
    cacheType: 'cashier_store_settings',
    dataKey: 'store_settings',
    payload: payload,
  );
}

void _expectSettings(StoreSettings? actual, StoreSettings expected) {
  expect(actual, isNotNull);
  expect(
    StoreSettingsModel.fromEntity(actual!).toJson(),
    StoreSettingsModel.fromEntity(expected).toJson(),
  );
}

class _StoreSettingsRepository implements StoreSettingsRepository {
  _StoreSettingsRepository(this.onGetSettings);

  final Future<StoreSettings> Function() onGetSettings;
  int getSettingsCalls = 0;

  @override
  Future<StoreSettings> getSettings() {
    getSettingsCalls++;
    return onGetSettings();
  }

  @override
  Future<StoreSettings> updateSettings(StoreSettings settings) =>
      throw UnimplementedError();

  @override
  Future<String> uploadLogo(ImageUploadInput image) =>
      throw UnimplementedError();
}

class _FailingCachedRecordsDao extends CachedRecordsDao {
  _FailingCachedRecordsDao(super.database);

  @override
  Future<CachedRecord> saveCache({
    required String cacheType,
    required String cacheKey,
    required Object? payload,
    DateTime? updatedAt,
  }) async {
    throw Exception('write failed');
  }
}
