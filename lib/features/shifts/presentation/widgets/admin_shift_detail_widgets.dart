part of '../pages/admin_shifts_page.dart';

class AdminShiftDetailBody extends StatelessWidget {
  const AdminShiftDetailBody({
    super.key,
    required this.detail,
    required this.onForceClose,
  });

  final AdminShiftDetail detail;
  final VoidCallback onForceClose;

  @override
  Widget build(BuildContext context) {
    final shift = detail.shift;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ShiftDetailHeader(shift: shift),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ShiftDetailMetric(
                      icon: Icons.payments_outlined,
                      label: 'Penjualan',
                      value: formatAdminShiftRupiah(shift.totalSales),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ShiftDetailMetric(
                      icon: Icons.receipt_long_outlined,
                      label: 'Transaksi',
                      value: '${shift.totalTransactions}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekap kas',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      _ShiftValue(
                        label: 'Modal awal',
                        value: formatAdminShiftRupiah(shift.startingCash),
                      ),
                      _ShiftValue(
                        label: 'Kas yang diharapkan',
                        value: formatAdminShiftRupiah(shift.expectedCash),
                      ),
                      if (shift.actualCash != null)
                        _ShiftValue(
                          label: 'Kas aktual',
                          value: formatAdminShiftRupiah(shift.actualCash!),
                        ),
                      if (shift.cashDifference != null)
                        _ShiftValue(
                          label: 'Selisih kas',
                          value: formatAdminShiftRupiah(shift.cashDifference!),
                          valueColor: shift.cashDifference == 0
                              ? const Color(0xFF16834A)
                              : Theme.of(context).colorScheme.error,
                        ),
                      const Divider(height: 24),
                      _ShiftValue(
                        label: 'Total penjualan',
                        value: formatAdminShiftRupiah(shift.totalSales),
                      ),
                      _ShiftValue(
                        label: 'Jumlah transaksi',
                        value: '${shift.totalTransactions}',
                      ),
                      if (shift.notes.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          'Catatan shift',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(shift.notes),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transaksi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${detail.transactions.length} catatan',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (detail.transactions.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('Belum ada transaksi pada shift.'),
                  ),
                )
              else
                ...detail.transactions.map(
                  (transaction) => _TransactionCard(transaction: transaction),
                ),
            ],
          ),
        ),
        if (shift.status == 'open')
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onForceClose,
                  icon: const Icon(Icons.lock_clock_outlined),
                  label: const Text('Paksa tutup shift'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ShiftValue extends StatelessWidget {
  const _ShiftValue({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor == null ? null : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftDetailHeader extends StatelessWidget {
  const _ShiftDetailHeader({required this.shift});

  final ActiveShift shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(adminShiftInitials(shift.cashierName ?? 'Kasir')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.cashierName ?? 'Kasir',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (shift.cashierEmail != null)
                        Text(
                          shift.cashierEmail!,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ShiftStatusChip(status: shift.status),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shift.outletName ?? 'Outlet',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ShiftValue(
              label: 'Mulai',
              value: formatAdminShiftDateTime(shift.startTime),
            ),
            _ShiftValue(
              label: 'Selesai',
              value: shift.endTime == null
                  ? 'Belum selesai'
                  : formatAdminShiftDateTime(shift.endTime!),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftDetailMetric extends StatelessWidget {
  const _ShiftDetailMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context) {
    final details = transaction.items
        .map((item) => '${item.quantity} × ${item.productName}')
        .join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _transactionStatus(transaction.status),
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatAdminShiftRupiah(transaction.totalAmount),
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${transaction.paymentMethod} · ${formatAdminShiftDateTime(transaction.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (details.isNotEmpty) ...[
              const Divider(height: 20),
              Text(details),
            ],
            if (transaction.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Catatan: ${transaction.notes}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _transactionStatus(String status) => switch (status.toLowerCase()) {
  'completed' => 'Selesai',
  'pending' => 'Belum lunas',
  'cancelled' => 'Dibatalkan',
  _ => status,
};
