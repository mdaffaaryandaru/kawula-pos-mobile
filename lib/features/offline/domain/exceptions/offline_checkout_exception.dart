class OfflineCheckoutException implements Exception {
  const OfflineCheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}
