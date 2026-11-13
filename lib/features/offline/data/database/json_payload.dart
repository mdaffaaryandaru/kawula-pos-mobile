import 'dart:convert';

String encodeJsonWithoutCredentials(Object? value) {
  _rejectCredentials(value);
  return jsonEncode(value);
}

void _rejectCredentials(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw ArgumentError.value(
          entry.key,
          'payload',
          'Semua key JSON harus berupa String.',
        );
      }

      final normalizedKey = (entry.key as String).toLowerCase().replaceAll(
        RegExp('[^a-z0-9]'),
        '',
      );
      if (const {
        'password',
        'pin',
        'token',
        'accesstoken',
        'refreshtoken',
      }.contains(normalizedKey)) {
        throw ArgumentError.value(
          entry.key,
          'payload',
          'Data kredensial tidak boleh disimpan di database lokal.',
        );
      }

      _rejectCredentials(entry.value);
    }
  } else if (value is Iterable) {
    for (final item in value) {
      _rejectCredentials(item);
    }
  }
}
