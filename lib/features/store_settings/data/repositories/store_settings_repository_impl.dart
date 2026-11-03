// Package imports:
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:kawula_pos/features/store_settings/data/datasources/store_settings_remote_data_source.dart';
import 'package:kawula_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';

class StoreSettingsRepositoryImpl implements StoreSettingsRepository {
  const StoreSettingsRepositoryImpl(this._remoteDataSource);

  final StoreSettingsRemoteDataSource _remoteDataSource;

  @override
  Future<StoreSettings> getSettings() => _remoteDataSource.getSettings();

  @override
  Future<StoreSettings> updateSettings(StoreSettings settings) =>
      _remoteDataSource.updateSettings(StoreSettingsModel.fromEntity(settings));

  @override
  Future<String> uploadLogo(XFile image) => _remoteDataSource.uploadLogo(image);
}
