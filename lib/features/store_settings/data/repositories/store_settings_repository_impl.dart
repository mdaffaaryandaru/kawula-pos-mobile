// Package imports:
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:kawula_pos/features/store_settings/data/datasources/store_settings_remote_data_source.dart';
import 'package:kawula_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/cached_records_dao.dart';

class StoreSettingsRepositoryImpl implements StoreSettingsRepository {
  const StoreSettingsRepositoryImpl(
    this._remoteDataSource, {
    CachedRecordsDao? cacheDao,
  }) : _cacheDao = cacheDao;

  final StoreSettingsRemoteDataSource _remoteDataSource;
  final CachedRecordsDao? _cacheDao;

  @override
  Future<StoreSettings> getSettings() async {
    final settings = await _remoteDataSource.getSettings();
    await _saveSettings(settings);
    return settings;
  }

  @override
  Future<StoreSettings> updateSettings(StoreSettings settings) async {
    final updated = await _remoteDataSource.updateSettings(
      StoreSettingsModel.fromEntity(settings),
    );
    await _saveSettings(updated);
    return updated;
  }

  @override
  Future<String> uploadLogo(XFile image) => _remoteDataSource.uploadLogo(image);

  Future<void> _saveSettings(StoreSettings settings) async {
    await _cacheDao?.saveCache(
      cacheType: 'store_settings',
      cacheKey: 'global',
      payload: StoreSettingsModel.fromEntity(settings).toJson(),
    );
  }
}
