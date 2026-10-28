import '../../../../config/api_config.dart';

num? parseNonNegativeNumber(String? value) {
  final number = num.tryParse(value ?? '');
  if (number == null || !number.isFinite || number < 0) return null;
  return number;
}

String formatProductRupiah(num value) {
  final digits = value.toInt().toString();
  final result = StringBuffer('Rp ');
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  return result.toString();
}

String formatProductNumber(num value) {
  if (value == value.toInt()) return value.toInt().toString();
  return value.toString();
}

String resolveProductImageUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed?.hasAuthority == true) return url;
  final apiBase = Uri.parse(ApiConfig.baseUrl);
  final basePath = apiBase.path.endsWith('/api')
      ? apiBase.path.substring(0, apiBase.path.length - 4)
      : apiBase.path;
  return apiBase.replace(path: basePath).resolve(url).toString();
}
