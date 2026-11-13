import 'package:flutter/material.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/offline/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/offline/domain/services/offline_transaction_reconciliation.dart';
import 'package:kawula_pos/features/offline/presentation/widgets/offline_transaction_formatters.dart';
import 'package:kawula_pos/features/offline/presentation/widgets/offline_transaction_receipt_mapper.dart';
import 'package:kawula_pos/features/transactions/presentation/models/transaction_receipt_data.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/transaction_receipt_card.dart';

String offlineReconciliationStatusLabel(String status) => switch (status) {
  'pending_sync' => 'Menunggu pengiriman data',
  'syncing' => 'Sedang disinkronkan',
  'synced' => 'Tersinkron',
  'failed' => 'Gagal',
  'needs_reconciliation' => 'Perlu pencocokan',
  'resolved_manually' => 'Diselesaikan manual',
  _ => status,
};

Map<String, dynamic> offlineReceiptSnapshot(
  OfflineTransactionQueueItem record,
) => parseOfflineReceiptSnapshot(record.receiptSnapshotJson);

String offlineReceiptField(OfflineTransactionQueueItem record, String key) {
  final value = offlineReceiptSnapshot(record)[key];
  return value is String ? value : '';
}

num offlineReceiptTotal(OfflineTransactionQueueItem record) {
  final snapshot = offlineReceiptSnapshot(record);
  final value =
      snapshot['total_amount'] ?? snapshot['total'] ?? snapshot['amount'];
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

Future<String?> showReconciliationCandidateDialog(
  BuildContext context,
  List<TransactionRecord> candidates, {
  required DateTime localCreatedAt,
}) => showDialog<String>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Transaksi yang ditemukan di sistem'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Daftar ini berasal dari histori yang dikembalikan server dan '
                'mungkin tidak mencakup semua transaksi. Kandidat di luar '
                'rentang utama ±24 jam tetap ditampilkan untuk pemeriksaan manual.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            ...candidates.map((candidate) {
              final withinTimeWindow =
                  isWithinOfflineReconciliationCandidateTimeWindow(
                    localCreatedAt: localCreatedAt,
                    remoteCreatedAt: candidate.createdAt,
                  );
              return ListTile(
                title: Text(candidate.id),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${candidate.cashierName} · ${candidate.status} · '
                      '${candidate.createdAt == null ? 'Waktu tidak tersedia' : formatOfflineTransactionDate(candidate.createdAt!)} · '
                      '${formatRupiah(candidate.totalAmount)}',
                    ),
                    if (!withinTimeWindow)
                      Text(
                        candidate.createdAt == null
                            ? 'Waktu server tidak tersedia.'
                            : 'Di luar rentang relevansi utama ±24 jam.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, candidate.id),
              );
            }),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tutup'),
      ),
    ],
  ),
);

Future<String?> showReconciliationMatchDialog(
  BuildContext context, {
  required OfflineTransactionQueueItem local,
  required TransactionRecord remote,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _ReconciliationMatchDialog(local: local, remote: remote),
);

Future<String?> showReconciliationReasonDialog(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _ReconciliationReasonDialog(title: title, message: message),
);

class OfflineReconciliationTransactionDetailDialog extends StatelessWidget {
  const OfflineReconciliationTransactionDetailDialog({
    super.key,
    required this.record,
    required this.audit,
  });

  final OfflineTransactionQueueItem record;
  final List<OfflineTransactionResolutionAudit> audit;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(record.localId),
    content: SizedBox(
      width: 600,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kasir: ${offlineReceiptField(record, 'cashier_name')}'),
            Text('User ID: ${record.ownerUserId}'),
            Text(
              'Outlet: ${offlineReceiptField(record, 'outlet_name')} (${record.outletId})',
            ),
            Text('Shift asal: ${record.shiftId}'),
            Text(
              'Waktu lokal: ${formatOfflineTransactionDate(record.createdAtLocal)}',
            ),
            Text('Total: ${formatRupiah(offlineReceiptTotal(record))}'),
            Text(
              'Metode pembayaran: ${offlineReceiptField(record, 'payment_method')}',
            ),
            Text('Jenis transaksi: ${record.transactionType}'),
            Text('Status: ${offlineReconciliationStatusLabel(record.status)}'),
            if (record.remoteTransactionId != null)
              Text('ID transaksi server: ${record.remoteTransactionId}'),
            if (record.status == 'resolved_manually' &&
                record.remoteTransactionId == null)
              const Text('Transaksi tidak tersinkron ke server.'),
            if (record.lastError != null)
              Text('Alasan gagal: ${record.lastError}'),
            const SizedBox(height: 12),
            const Text('Data struk:'),
            _buildLocalReceipt(record),
            if (audit.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Riwayat penanganan:'),
              for (final entry in audit)
                Text(
                  '${entry.resolutionType} · Admin ${entry.resolvingAdminUserId} '
                  '(${entry.resolvingAdminRole}) · '
                  '${formatOfflineTransactionDate(entry.resolvedAt)}\n'
                  '${entry.reason}'
                  '${entry.notes == null ? '' : '\n${entry.notes}'}',
                ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Tutup'),
      ),
    ],
  );
}

class _ReconciliationMatchDialog extends StatefulWidget {
  const _ReconciliationMatchDialog({required this.local, required this.remote});

  final OfflineTransactionQueueItem local;
  final TransactionRecord remote;

  @override
  State<_ReconciliationMatchDialog> createState() =>
      _ReconciliationMatchDialogState();
}

class _ReconciliationMatchDialogState
    extends State<_ReconciliationMatchDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.local;
    final remote = widget.remote;
    final localTotal = offlineReceiptTotal(local);
    return AlertDialog(
      title: const Text('Periksa dan Cocokkan transaksi'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lokal: ${local.localId}'),
              Text('Server: ${remote.id}'),
              const SizedBox(height: 8),
              Text(
                'Waktu lokal: ${formatOfflineTransactionDate(local.createdAtLocal)}\n'
                'Waktu server: ${remote.createdAt == null ? 'Tidak tersedia' : formatOfflineTransactionDate(remote.createdAt!)}\n'
                'Kasir: ${local.ownerUserId} / ${remote.cashierId}\n'
                'Outlet: ${local.outletId} / ${remote.outletId}\n'
                'Total lokal/server: ${formatRupiah(localTotal)} / ${formatRupiah(remote.totalAmount)}\n'
                'Selisih total: ${formatRupiah((remote.totalAmount - localTotal).abs())}\n'
                'Pembayaran: ${offlineReceiptField(local, 'payment_method')} / ${remote.paymentMethod}',
              ),
              if (!isWithinOfflineReconciliationCandidateTimeWindow(
                localCreatedAt: local.createdAtLocal,
                remoteCreatedAt: remote.createdAt,
              ))
                Text(
                  'Peringatan: kandidat di luar rentang relevansi utama ±24 jam.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              const Text('Struk transaksi lokal:'),
              _buildLocalReceipt(local),
              const SizedBox(height: 12),
              const Text('Transaksi server:'),
              TransactionReceiptCard(
                receipt: TransactionReceiptData.fromTransaction(remote),
                showUnitPrice: true,
                showPaymentStatus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Alasan keputusan Admin (wajib)',
                ),
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _reasonController.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _reasonController.text.trim()),
          child: const Text('Cocokkan transaksi'),
        ),
      ],
    );
  }
}

Widget _buildLocalReceipt(OfflineTransactionQueueItem record) {
  final receipt = buildOfflineReceiptData(record);
  if (receipt == null) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: Text('Detail struk tidak tersedia')),
    );
  }
  return TransactionReceiptCard(receipt: receipt, showUnitPrice: true);
}

class _ReconciliationReasonDialog extends StatefulWidget {
  const _ReconciliationReasonDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  State<_ReconciliationReasonDialog> createState() =>
      _ReconciliationReasonDialogState();
}

class _ReconciliationReasonDialogState
    extends State<_ReconciliationReasonDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.message),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'Alasan keputusan Admin (wajib)',
          ),
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _reasonController.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, _reasonController.text.trim()),
        child: const Text('Konfirmasi'),
      ),
    ],
  );
}
