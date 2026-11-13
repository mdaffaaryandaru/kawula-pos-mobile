import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/offline/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/transaction_receipt_card.dart';
import 'package:kawula_pos/features/offline/presentation/widgets/offline_transaction_formatters.dart';
import 'package:kawula_pos/features/offline/presentation/widgets/offline_transaction_receipt_mapper.dart';

class OfflineQueueSummary extends StatelessWidget {
  const OfflineQueueSummary({
    super.key,
    required this.shiftTransactions,
    required this.syncedCount,
  });

  final List<OfflineTransactionQueueItem> shiftTransactions;
  final int syncedCount;

  @override
  Widget build(BuildContext context) {
    int countFor(String status) =>
        shiftTransactions.where((record) => record.status == status).length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Antrean shift aktif',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: 'Menunggu',
                count: countFor('pending_sync'),
                color: Colors.orange,
              ),
              _SummaryChip(
                label: 'Sedang disinkronkan',
                count: countFor('syncing'),
                color: Colors.blue,
              ),
              _SummaryChip(
                label: 'Gagal',
                count: countFor('failed'),
                color: Colors.red,
              ),
              _SummaryChip(
                label: 'Pencocokan',
                count: countFor('needs_reconciliation'),
                color: Colors.purple,
              ),
              _SummaryChip(
                label: 'Tersinkron',
                count: syncedCount,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OfflineQueueStatusFilter extends StatelessWidget {
  const OfflineQueueStatusFilter({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  final String selectedStatus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedStatus,
        decoration: const InputDecoration(
          labelText: 'Filter status',
          isDense: true,
        ),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Semua status')),
          DropdownMenuItem(value: 'pending_sync', child: Text('Menunggu')),
          DropdownMenuItem(value: 'syncing', child: Text('Menyinkron')),
          DropdownMenuItem(value: 'synced', child: Text('Tersinkron')),
          DropdownMenuItem(value: 'failed', child: Text('Gagal')),
          DropdownMenuItem(
            value: 'needs_reconciliation',
            child: Text('Pencocokan'),
          ),
          DropdownMenuItem(
            value: 'resolved_manually',
            child: Text('Diselesaikan manual'),
          ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class OfflineQueueTransactionTile extends StatelessWidget {
  const OfflineQueueTransactionTile({
    super.key,
    required this.record,
    required this.onTap,
  });

  final OfflineTransactionQueueItem record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record.status);
    return Card(
      child: ListTile(
        title: Text(
          '${record.localId} · ${record.transactionType.toUpperCase()}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${formatOfflineTransactionDate(record.createdAtLocal)} · '
              '${formatRupiah(_extractAmount(record))}',
            ),
            if (record.lastError != null && record.lastError!.isNotEmpty)
              Text(
                record.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(_statusLabel(record.status)),
          backgroundColor: statusColor.withValues(alpha: 0.15),
          side: BorderSide(color: statusColor.withValues(alpha: 0.45)),
        ),
        onTap: onTap,
      ),
    );
  }

  static num _extractAmount(OfflineTransactionQueueItem record) {
    try {
      final parsed = jsonDecode(record.receiptSnapshotJson);
      if (parsed is! Map<String, dynamic>) return 0;
      final total =
          parsed['total_amount'] ?? parsed['total'] ?? parsed['amount'];
      if (total is num) return total;
      if (total is String) return num.tryParse(total) ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  static String _statusLabel(String status) => switch (status) {
    'pending_sync' => 'Menunggu',
    'syncing' => 'Menyinkron',
    'synced' => 'Tersinkron',
    'failed' => 'Gagal',
    'needs_reconciliation' => 'Pencocokan',
    'resolved_manually' => 'Diselesaikan manual',
    _ => status,
  };

  static Color _statusColor(String status) => switch (status) {
    'pending_sync' => Colors.orange,
    'syncing' => Colors.blue,
    'synced' => Colors.green,
    'failed' => Colors.red,
    'needs_reconciliation' => Colors.purple,
    'resolved_manually' => Colors.blueGrey,
    _ => Colors.grey,
  };
}

class OfflineQueueTransactionDetailDialog extends StatelessWidget {
  const OfflineQueueTransactionDetailDialog({
    super.key,
    required this.record,
    required this.audit,
  });

  final OfflineTransactionQueueItem record;
  final List<OfflineTransactionResolutionAudit> audit;

  @override
  Widget build(BuildContext context) {
    final receipt = buildOfflineReceiptData(record);
    final screenSize = MediaQuery.sizeOf(context);
    final isOpenBill = record.transactionType == 'open_bill';
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      title: const Text('Detail Transaksi'),
      content: SizedBox(
        width: (screenSize.width - 80).clamp(0.0, 480.0).toDouble(),
        height: (screenSize.height * 0.62).clamp(180.0, 560.0).toDouble(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(
                      isOpenBill
                          ? 'Open Bill · Belum lunas'
                          : 'Jenis: ${record.transactionType}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      OfflineQueueTransactionTile._statusLabel(record.status),
                    ),
                    backgroundColor: OfflineQueueTransactionTile._statusColor(
                      record.status,
                    ).withValues(alpha: 0.15),
                    side: BorderSide(
                      color: OfflineQueueTransactionTile._statusColor(
                        record.status,
                      ).withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
              if (record.remoteTransactionId != null)
                Text('ID transaksi server: ${record.remoteTransactionId}'),
              if (record.status == 'resolved_manually' &&
                  record.remoteTransactionId == null)
                const Text('Transaksi tidak tersinkron ke server.'),
              if (audit.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final entry in audit)
                  Text(
                    'Resolusi: ${entry.resolutionType}\n'
                    'Admin: ${entry.resolvingAdminUserId} '
                    '(${entry.resolvingAdminRole})\n'
                    'Alasan: ${entry.reason}'
                    '${entry.notes == null ? '' : '\nCatatan: ${entry.notes}'}',
                  ),
                const SizedBox(height: 8),
              ],
              if (receipt == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Detail struk tidak tersedia')),
                )
              else
                TransactionReceiptCard(receipt: receipt, showUnitPrice: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class OfflineQueuePinDialog extends StatefulWidget {
  const OfflineQueuePinDialog({super.key});

  @override
  State<OfflineQueuePinDialog> createState() => _OfflineQueuePinDialogState();
}

class _OfflineQueuePinDialogState extends State<OfflineQueuePinDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Antrean pengiriman data'),
    content: TextField(
      controller: _controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 4,
      decoration: const InputDecoration(
        labelText: 'PIN',
        hintText: 'Masukkan PIN akun',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: const Text('Sinkronkan'),
      ),
    ],
  );
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text('$label: $count'),
  );
}

class OfflineQueuePendingCountBadge extends StatelessWidget {
  const OfflineQueuePendingCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
