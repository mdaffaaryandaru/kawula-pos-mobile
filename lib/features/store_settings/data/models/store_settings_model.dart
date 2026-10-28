import '../../domain/entities/store_settings.dart';

class StoreSettingsModel extends StoreSettings {
  const StoreSettingsModel({
    required super.storeName,
    required super.address,
    required super.logoUrl,
    required super.taxPercentage,
    required super.serviceCharge,
    required super.autoCloseShiftEnabled,
    required super.autoCloseShiftTime,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    final storeName = json['store_name'];
    final address = json['address'];
    final logoUrl = json['logo_url'];
    final taxPercentage = json['tax_percentage'];
    final serviceCharge = json['service_charge'];
    final autoCloseShiftEnabled = json['auto_close_shift_enabled'];
    final autoCloseShiftTime = json['auto_close_shift_time'];
    if (storeName is! String ||
        address is! String ||
        logoUrl is! String ||
        taxPercentage is! num ||
        serviceCharge is! num ||
        autoCloseShiftEnabled is! bool ||
        autoCloseShiftTime is! String) {
      throw const FormatException('Data pengaturan toko tidak valid.');
    }
    return StoreSettingsModel(
      storeName: storeName,
      address: address,
      logoUrl: logoUrl,
      taxPercentage: taxPercentage,
      serviceCharge: serviceCharge,
      autoCloseShiftEnabled: autoCloseShiftEnabled,
      autoCloseShiftTime: autoCloseShiftTime,
    );
  }

  factory StoreSettingsModel.fromEntity(StoreSettings settings) =>
      StoreSettingsModel(
        storeName: settings.storeName,
        address: settings.address,
        logoUrl: settings.logoUrl,
        taxPercentage: settings.taxPercentage,
        serviceCharge: settings.serviceCharge,
        autoCloseShiftEnabled: settings.autoCloseShiftEnabled,
        autoCloseShiftTime: settings.autoCloseShiftTime,
      );

  Map<String, Object> toJson() => {
    'store_name': storeName,
    'address': address,
    'logo_url': logoUrl,
    'tax_percentage': taxPercentage,
    'service_charge': serviceCharge,
    'auto_close_shift_enabled': autoCloseShiftEnabled,
    'auto_close_shift_time': autoCloseShiftTime,
  };
}
