// Project imports:
import 'package:kawula_pos/features/shared/domain/value_objects/image_upload_input.dart';
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';

abstract interface class StoreSettingsRepository {
  Future<StoreSettings> getSettings();

  Future<StoreSettings> updateSettings(StoreSettings settings);

  Future<String> uploadLogo(ImageUploadInput image);
}
