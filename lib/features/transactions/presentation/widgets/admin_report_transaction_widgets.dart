part of '../pages/admin_transaction_report_page.dart';

class _TransactionsTable extends StatelessWidget {
  const _TransactionsTable({required this.transactions, required this.onTap});

  final List<TransactionRecord> transactions;
  final ValueChanged<TransactionRecord> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 760) {
        return Column(
          children: transactions
              .map((transaction) => _transactionCard(context, transaction))
              .toList(growable: false),
        );
      }
      final header = Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
        letterSpacing: .6,
      );
      return ResponsiveDataTable(
        minWidth: constraints.maxWidth,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(17),
        ),
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFC)),
        horizontalMargin: 16,
        columnSpacing: 22,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 72,
        columns: [
          DataColumn(label: Text('WAKTU & ID', style: header)),
          DataColumn(label: Text('OUTLET', style: header)),
          DataColumn(label: Text('KASIR & MEMBER', style: header)),
          DataColumn(label: Text('ITEM', style: header)),
          DataColumn(label: Text('METODE & TOTAL', style: header)),
          DataColumn(label: Text('STATUS', style: header)),
          DataColumn(label: Text('AKSI', style: header)),
        ],
        rows: transactions
            .map(
              (transaction) => DataRow(
                onSelectChanged: (_) => onTap(transaction),
                cells: [
                  DataCell(
                    SizedBox(
                      width: 125,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateTime(transaction.createdAt),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            transaction.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 90,
                      child: Text(
                        transaction.outletName.isEmpty
                            ? '—'
                            : transaction.outletName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 110,
                      child: Text(
                        'Kasir: ${transaction.cashierName.isEmpty ? '—' : transaction.cashierName}\n'
                        'Member: ${transaction.memberName.isEmpty ? '—' : transaction.memberName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${transaction.items.fold<int>(0, (total, item) => total + item.quantity)} Pcs',
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 118,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatRupiah(transaction.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            transaction.paymentMethod,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(_StatusBadge(status: transaction.status)),
                  DataCell(
                    OutlinedButton.icon(
                      onPressed: () => onTap(transaction),
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('Detail'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      );
    },
  );

  Widget _transactionCard(
    BuildContext context,
    TransactionRecord transaction,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap(transaction),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(transaction.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                _StatusBadge(status: transaction.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.items.isEmpty
                        ? 'Transaksi ${transaction.id}'
                        : transaction.items
                              .map((item) => item.productName)
                              .join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _formatRupiah(transaction.totalAmount),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${transaction.paymentMethod} · ${transaction.items.fold<int>(0, (total, item) => total + item.quantity)} item',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (transaction.outletName.isNotEmpty ||
                transaction.cashierName.isNotEmpty ||
                transaction.memberName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (transaction.outletName.isNotEmpty) transaction.outletName,
                  if (transaction.cashierName.isNotEmpty)
                    'Kasir: ${transaction.cashierName}',
                  if (transaction.memberName.isNotEmpty)
                    'Member: ${transaction.memberName}',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              transaction.id,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
