// Package imports:
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';

abstract interface class StoreSettingsRepository {
  Future<StoreSettings> getSettings();

  Future<StoreSettings> updateSettings(StoreSettings settings);

  Future<String> uploadLogo(XFile image);
}
