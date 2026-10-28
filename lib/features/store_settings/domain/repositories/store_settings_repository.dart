import 'package:image_picker/image_picker.dart';

import '../entities/store_settings.dart';

abstract interface class StoreSettingsRepository {
  Future<StoreSettings> getSettings();

  Future<StoreSettings> updateSettings(StoreSettings settings);

  Future<String> uploadLogo(XFile image);
}
