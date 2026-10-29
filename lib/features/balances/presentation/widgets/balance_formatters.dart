import 'package:flutter/material.dart';

String historyTypeLabel(String type) => switch (type) {
  'initial' => 'Saldo awal',
  'adjustment' => 'Penyesuaian',
  'sales' => 'Penjualan',
  'expense' => 'Pengeluaran',
  'refund' => 'Refund',
  _ => type,
};

String paymentMethodLabel(String method) => switch (method.toUpperCase()) {
  'CASH' => 'Cash',
  'CARD' => 'Debit / Kredit',
  'QRIS' => 'QRIS',
  'BANK_TRANSFER' || 'TRANSFER' || 'BANK' => 'Transfer Bank',
  'OPEN_BILL' => 'Open Bill',
  _ => method,
};

IconData paymentMethodIcon(String method) => switch (method.toUpperCase()) {
  'CASH' => Icons.volunteer_activism_outlined,
  'BANK_TRANSFER' || 'TRANSFER' || 'BANK' => Icons.account_balance_outlined,
  _ => Icons.monetization_on_outlined,
};

String signedBalanceAmount(num amount) =>
    '${amount > 0
        ? '+'
        : amount < 0
        ? '-'
        : ''} ${formatBalanceRupiah(amount.abs())}';

String formatBalanceRupiah(num amount) {
  final digits = amount.abs().toInt().toString();
  final result = StringBuffer(amount < 0 ? '- Rp ' : 'Rp ');
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  if (amount % 1 != 0) {
    result
      ..write(',')
      ..write((amount.abs() % 1).toStringAsFixed(2).substring(2));
  }
  return result.toString();
}

String formatBalanceDateTime(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}, '
      '${twoDigits(local.hour)}.${twoDigits(local.minute)}.'
      '${twoDigits(local.second)}';
}
