part of '../pages/admin_dashboard_page.dart';

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({
    required this.transactions,
    required this.availableWidth,
    required this.onOpenReport,
  });

  final List<TransactionRecord> transactions;
  final double availableWidth;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) {
    final isWide = availableWidth >= 850;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Transaksi Terbaru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenReport,
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const _EmptyTransactions()
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(18),
            ),
            child: isWide
                ? _TransactionTable(transactions: transactions)
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < transactions.length;
                        index++
                      ) ...[
                        _TransactionCard(transaction: transactions[index]),
                        if (index != transactions.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
          ),
      ],
    );
  }
}

class _TransactionTable extends StatelessWidget {
  const _TransactionTable({required this.transactions});

  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: .6,
    );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.3),
        1: FlexColumnWidth(1.0),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.0),
        4: FlexColumnWidth(1.0),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFC)),
          children: [
            _TableCell('ID TRANSAKSI', style: headerStyle),
            _TableCell('ITEM', style: headerStyle),
            _TableCell('TOTAL', style: headerStyle),
            _TableCell('STATUS', style: headerStyle),
            _TableCell('WAKTU', style: headerStyle),
          ],
        ),
        for (final transaction in transactions)
          TableRow(
            children: [
              _TableCell(_shortId(transaction.id)),
              _TableCell('${_itemCount(transaction)} item'),
              _TableCell(
                _formatRupiah(transaction.totalAmount),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _TableCell.child(
                child: _TransactionStatus(status: transaction.status),
              ),
              _TableCell.child(
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(_formatTime(transaction.createdAt)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text, {this.style}) : child = null;

  const _TableCell.child({required this.child}) : text = null, style = null;

  final String? text;
  final TextStyle? style;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    child:
        child ??
        Text(
          text ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style ?? const TextStyle(color: AppColors.textSecondary),
        ),
  );
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.dashboardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shortId(transaction.id),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _TransactionStatus(status: transaction.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_itemCount(transaction)} item · '
                  '${_formatTime(transaction.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatRupiah(transaction.totalAmount),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionStatus extends StatelessWidget {
  const _TransactionStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final color = switch (normalizedStatus) {
      'completed' => AppColors.success,
      'pending' => AppColors.warning,
      'refunded' || 'cancelled' => AppColors.danger,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _statusLabel(normalizedStatus),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
