import 'package:flutter/material.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/auto_close_shift_schedule.dart';
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class CatalogActiveShiftBanner extends StatelessWidget {
  const CatalogActiveShiftBanner({
    super.key,
    required this.shift,
    required this.onManageShift,
  });

  final ActiveShift shift;
  final VoidCallback onManageShift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = shift.startTime.toLocal();
    final time =
        '${startTime.hour.toString().padLeft(2, '0')}:'
        '${startTime.minute.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8FBF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Shift Aktif',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const SizedBox(width: 4),
                    const _LiveStatusDot(),
                  ],
                ),
                Text(
                  '${shift.outletName ?? 'Outlet'} · Mulai $time · '
                  'Kas awal ${formatRupiah(shift.startingCash)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onManageShift,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Tutup Shift'),
          ),
        ],
      ),
    );
  }
}

class CatalogAutoCloseWarning extends StatelessWidget {
  const CatalogAutoCloseWarning({
    super.key,
    required this.settings,
    required this.isEstimated,
    required this.queueCount,
    required this.onOpenQueue,
  });

  final StoreSettings? settings;
  final bool isEstimated;
  final int queueCount;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final currentSettings = settings;
    if (currentSettings == null ||
        !currentSettings.autoCloseShiftEnabled ||
        queueCount == 0) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final autoCloseAt = AutoCloseShiftSchedule.nextClosingAt(
      currentSettings.autoCloseShiftTime,
      now,
    );
    if (autoCloseAt == null ||
        !AutoCloseShiftSchedule.shouldWarn(
          enabled: currentSettings.autoCloseShiftEnabled,
          unresolvedCount: queueCount,
          configuredTime: currentSettings.autoCloseShiftTime,
          now: now,
        )) {
      return const SizedBox.shrink();
    }

    final remaining = autoCloseAt.difference(now);
    final time =
        '${autoCloseAt.hour.toString().padLeft(2, '0')}:'
        '${autoCloseAt.minute.toString().padLeft(2, '0')}';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final remainingText = hours > 0
        ? '$hours jam $minutes menit'
        : minutes > 0
        ? '$minutes menit'
        : 'kurang dari 1 menit';
    final estimateMessage = isEstimated
        ? ' Estimasi dari cache terakhir.'
        : ' Estimasi waktu lokal; zona waktu server belum diverifikasi.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Shift diperkirakan ditutup otomatis pukul $time '
              '(sekitar $remainingText). Masih ada $queueCount transaksi '
              'yang belum terselesaikan.$estimateMessage',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onOpenQueue,
            child: const Text('Lihat antrean'),
          ),
        ],
      ),
    );
  }
}

class _LiveStatusDot extends StatelessWidget {
  const _LiveStatusDot();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .45, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOut,
    builder: (context, opacity, child) =>
        Opacity(opacity: opacity, child: child),
    child: const Icon(Icons.circle, size: 8, color: AppColors.success),
  );
}
