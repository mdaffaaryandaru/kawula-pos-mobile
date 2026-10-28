class StoreSettings {
  const StoreSettings({
    required this.storeName,
    required this.address,
    required this.logoUrl,
    required this.taxPercentage,
    required this.serviceCharge,
    required this.autoCloseShiftEnabled,
    required this.autoCloseShiftTime,
  });

  final String storeName;
  final String address;
  final String logoUrl;
  final num taxPercentage;
  final num serviceCharge;
  final bool autoCloseShiftEnabled;
  final String autoCloseShiftTime;
}
