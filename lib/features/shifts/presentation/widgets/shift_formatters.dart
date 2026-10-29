String formatShiftRupiah(num amount) {
  final digits = amount.round().abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${amount < 0 ? '- ' : ''}Rp $grouped';
}

String formatShiftTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String formatShiftDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final date = local.toIso8601String();
  return '${date.substring(0, 10)} ${date.substring(11, 16)}';
}
