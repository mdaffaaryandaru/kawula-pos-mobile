// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/transactions/presentation/pages/admin_transaction_report_page.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'completed' => const Color(0xFF059669),
      'pending' => const Color(0xFFD97706),
      'refunded' => const Color(0xFF7C3AED),
      'cancelled' => const Color(0xFFDC2626),
      _ => AppColors.textSecondary,
    };
    final background = switch (normalized) {
      'completed' => const Color(0xFFD1FAE5),
      'pending' => const Color(0xFFFEF3C7),
      'refunded' => const Color(0xFFEDE9FE),
      'cancelled' => const Color(0xFFFEE2E2),
      _ => const Color(0xFFF1F5F9),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
