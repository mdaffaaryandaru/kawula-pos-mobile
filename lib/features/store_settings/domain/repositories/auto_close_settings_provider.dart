import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';

class AutoCloseSettingsResult {
  const AutoCloseSettingsResult({
    this.settings,
    this.isEstimated = false,
    this.errorMessage,
  });

  final StoreSettings? settings;
  final bool isEstimated;
  final String? errorMessage;
}

abstract interface class AutoCloseSettingsProvider {
  Future<AutoCloseSettingsResult> getAutoCloseSettings({
    required String role,
    required String userId,
    required String? outletId,
  });
}
