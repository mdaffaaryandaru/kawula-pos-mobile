// Flutter imports:
import 'package:flutter/material.dart';

class CatalogOpenBillsPanel extends StatelessWidget {
  const CatalogOpenBillsPanel({
    super.key,
    required this.billCount,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onViewBills,
  });

  final int billCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onViewBills;

  @override
  Widget build(BuildContext context) {
    if (billCount == 0 && errorMessage == null) {
      return const SizedBox.shrink();
    }

    final hasError = errorMessage != null;
    final foreground = hasError
        ? Theme.of(context).colorScheme.error
        : const Color(0xFFB45309);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasError
            ? Theme.of(context).colorScheme.errorContainer
            : const Color(0xFFFFFBEB),
        border: Border.all(
          color: hasError
              ? Theme.of(context).colorScheme.error.withValues(alpha: .35)
              : const Color(0xFFFBBF24),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.schedule_outlined,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError
                      ? 'Open Bill tidak dapat dimuat'
                      : 'Open Bill ($billCount)',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hasError
                      ? errorMessage!
                      : 'Ada tagihan tertunda yang belum dilunasi',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isLoading
                ? null
                : hasError
                ? onRetry
                : onViewBills,
            style: TextButton.styleFrom(
              foregroundColor: foreground,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              isLoading
                  ? 'Memuat...'
                  : hasError
                  ? 'Coba Lagi'
                  : 'Lihat Tagihan',
            ),
          ),
        ],
      ),
    );
  }
}
