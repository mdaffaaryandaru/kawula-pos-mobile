part of '../pages/admin_transaction_report_page.dart';

class _ProfitSummary extends StatelessWidget {
  const _ProfitSummary({
    required this.sales,
    required this.cogs,
    required this.serviceCharge,
    required this.tax,
    required this.expenses,
    required this.netProfit,
    required this.expenseEntries,
  });

  final num sales;
  final num cogs;
  final num serviceCharge;
  final num tax;
  final num expenses;
  final num netProfit;
  final List<BalanceHistoryEntry> expenseEntries;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rincian Laba Bersih',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              'Omzet − HPP − Layanan − Pajak − Biaya',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ProfitLine(label: 'Omzet Penjualan (Lunas)', amount: sales),
        _ProfitLine(label: 'HPP / Modal Bahan', amount: -cogs),
        _ProfitLine(label: 'Service Charge', amount: -serviceCharge),
        _ProfitLine(label: 'Pajak (PPN)', amount: -tax),
        _ProfitLine(label: 'Biaya Operasional', amount: -expenses),
        const Divider(height: 22),
        _ProfitLine(label: 'Laba Bersih', amount: netProfit, emphasize: true),
        if (expenseEntries.isNotEmpty) ...[
          const Divider(height: 22),
          const Text(
            'BIAYA OPERASIONAL PERIODE INI',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 5),
          ...expenseEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.notes.isEmpty ? 'Biaya operasional' : entry.notes} · '
                      '${entry.paymentMethod} · ${_formatDateTime(entry.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    '-${_formatRupiah(entry.amount.abs())}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProfitLine extends StatelessWidget {
  const _ProfitLine({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final num amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasize ? AppColors.success : AppColors.textSecondary,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.normal,
              fontSize: emphasize ? 14 : 12,
            ),
          ),
        ),
        Text(
          _formatRupiah(amount),
          style: TextStyle(
            color: amount < 0
                ? AppColors.danger
                : emphasize
                ? AppColors.success
                : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: emphasize ? 14 : 12,
          ),
        ),
      ],
    ),
  );
}
