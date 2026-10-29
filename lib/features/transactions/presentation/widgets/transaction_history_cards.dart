part of '../pages/transactions_history_page.dart';

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, this.onSettle});

  final TransactionRecord transaction;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final status = transaction.status.toLowerCase();
    final (statusLabel, statusColor, statusIcon) = switch (status) {
      'completed' => (
        'Lunas',
        const Color(0xFF16834A),
        Icons.check_circle_outline,
      ),
      'pending' => (
        'Open bill',
        const Color(0xFFC17A00),
        Icons.pending_actions,
      ),
      'cancelled' => (
        'Dibatalkan',
        Theme.of(context).colorScheme.error,
        Icons.cancel_outlined,
      ),
      'refunded' => (
        'Refund',
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.currency_exchange,
      ),
      _ => (
        transaction.status,
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.receipt_long_outlined,
      ),
    };
    final date = transaction.createdAt;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          foregroundColor: statusColor,
          child: Icon(statusIcon),
        ),
        title: Text(
          formatRupiah(transaction.totalAmount),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _TransactionStatusChip(label: statusLabel, color: statusColor),
              Text(
                date == null ? 'Waktu tidak tersedia' : _formatDate(date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 8),
          if (transaction.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rincian item tidak disertakan pada respons transaksi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            for (final item in transaction.items) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity} × ${item.productName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(formatRupiah(item.price * item.quantity)),
                  ],
                ),
              ),
              if (item.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Catatan: ${item.notes}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          const Divider(height: 20),
          _DetailRow(label: 'No. transaksi', value: transaction.id),
          _DetailRow(label: 'Metode', value: transaction.paymentMethod),
          if (transaction.isPending)
            _DetailRow(label: 'Status', value: 'Menunggu pelunasan'),
          if (!transaction.isPending) ...[
            _DetailRow(
              label: 'Dibayar',
              value: formatRupiah(transaction.paidAmount),
            ),
            _DetailRow(
              label: 'Kembalian',
              value: formatRupiah(transaction.changeAmount),
            ),
          ],
          if (transaction.notes.isNotEmpty)
            _DetailRow(label: 'Catatan', value: transaction.notes),
          if (onSettle != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSettle,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Lunasi open bill'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}

class _TransactionStatusChip extends StatelessWidget {
  const _TransactionStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
