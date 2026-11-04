Uri buildApiUri(String baseUrl, String path) {
  final normalizedBaseUrl = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  return Uri.parse('$normalizedBaseUrl/$path');
}
