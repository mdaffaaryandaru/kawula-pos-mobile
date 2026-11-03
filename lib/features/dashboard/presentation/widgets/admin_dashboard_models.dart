// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tint,
    required this.detail,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
  final String detail;
}

class DashboardAction {
  const DashboardAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
}

String formatDashboardRupiah(num amount) {
  final digits = amount.round().abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${amount < 0 ? '- ' : ''}Rp $grouped';
}

String formatDashboardTime(DateTime? time) {
  if (time == null) return '--:--';
  final localTime = time.toLocal();
  return '${localTime.hour.toString().padLeft(2, '0')}:'
      '${localTime.minute.toString().padLeft(2, '0')}';
}

String formatDashboardDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String dashboardShortId(String id) => id.length > 6
    ? id.substring(id.length - 6).toUpperCase()
    : id.toUpperCase();

int dashboardItemCount(TransactionRecord transaction) =>
    transaction.items.fold<int>(0, (total, item) => total + item.quantity);

String dashboardStatusLabel(String status) => switch (status) {
  'completed' => 'Selesai',
  'pending' => 'Open bill',
  'refunded' => 'Refund',
  'cancelled' => 'Dibatalkan',
  _ => status,
};
