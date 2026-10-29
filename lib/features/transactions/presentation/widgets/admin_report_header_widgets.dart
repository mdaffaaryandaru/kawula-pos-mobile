part of '../pages/admin_transaction_report_page.dart';

class _ReportData {
  const _ReportData({required this.transactions, required this.history});

  final List<TransactionRecord> transactions;
  final List<BalanceHistoryEntry> history;
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.onExpense, required this.onRefresh});

  final VoidCallback? onExpense;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onExpense != null)
              FilledButton.icon(
                onPressed: onExpense,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Catat Biaya'),
              ),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh'),
            ),
          ],
        );
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'L A P O R A N',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Transaksi Masuk',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Default menampilkan transaksi hari ini, termasuk penjualan, open bill, dan pembatalan.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        );
        if (constraints.maxWidth >= 700) {
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 14),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [title, const SizedBox(height: 14), actions],
        );
      },
    ),
  );
}
