import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/transactions/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/transactions/presentation/models/transaction_receipt_data.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/transaction_receipt_card.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/offline_transaction_formatters.dart';

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
                label: 'Rekonsiliasi',
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
            child: Text('Rekonsiliasi'),
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
    'needs_reconciliation' => 'Rekonsiliasi',
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
    final receipt = _buildOfflineReceiptData(record);
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

TransactionReceiptData? _buildOfflineReceiptData(
  OfflineTransactionQueueItem record,
) {
  Object? decoded;
  try {
    decoded = jsonDecode(record.receiptSnapshotJson);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final snapshot = decoded;
  final storeName = snapshot['store_name'];
  final paymentMethod = snapshot['payment_method'];
  final totalAmount = snapshot['total_amount'];
  final paidAmount = snapshot['paid_amount'];
  final changeAmount = snapshot['change_amount'];
  final rawItems = snapshot['items'];
  if (storeName is! String ||
      storeName.trim().isEmpty ||
      paymentMethod is! String ||
      paymentMethod.trim().isEmpty ||
      totalAmount is! num ||
      !totalAmount.isFinite ||
      paidAmount is! num ||
      !paidAmount.isFinite ||
      changeAmount is! num ||
      !changeAmount.isFinite ||
      rawItems is! List ||
      rawItems.isEmpty) {
    return null;
  }

  const optionalStringFields = [
    'address',
    'logo_url',
    'outlet_name',
    'cashier_name',
    'member_name',
    'table_number',
    'notes',
  ];
  if (optionalStringFields.any(
    (key) =>
        snapshot.containsKey(key) &&
        snapshot[key] != null &&
        snapshot[key] is! String,
  )) {
    return null;
  }
  const optionalAmountFields = [
    'subtotal',
    'tax_amount',
    'service_charge',
    'discount_amount',
  ];
  if (optionalAmountFields.any((key) {
    final value = snapshot[key];
    return value != null && (value is! num || !value.isFinite);
  })) {
    return null;
  }

  final items = <TransactionReceiptItem>[];
  for (final rawItem in rawItems) {
    if (rawItem is! Map<String, dynamic>) return null;
    final productName = rawItem['product_name'];
    final quantity = rawItem['quantity'];
    final unitPrice = rawItem['unit_price'];
    final rawVariants = rawItem['selected_variants'];
    final notes = rawItem['notes'];
    if (productName is! String ||
        productName.trim().isEmpty ||
        quantity is! int ||
        quantity <= 0 ||
        unitPrice is! num ||
        !unitPrice.isFinite ||
        (rawVariants != null && rawVariants is! List) ||
        (notes != null && notes is! String)) {
      return null;
    }

    final variants = <TransactionReceiptVariant>[];
    if (rawVariants is List) {
      for (final rawVariant in rawVariants) {
        if (rawVariant is! Map<String, dynamic>) return null;
        final groupName = rawVariant['group_name'];
        final optionName = rawVariant['option_name'];
        if (groupName is! String ||
            groupName.trim().isEmpty ||
            optionName is! String ||
            optionName.trim().isEmpty) {
          return null;
        }
        variants.add(
          TransactionReceiptVariant(
            groupName: groupName,
            optionName: optionName,
          ),
        );
      }
    }
    items.add(
      TransactionReceiptItem(
        productName: productName,
        quantity: quantity,
        price: unitPrice,
        notes: notes is String ? notes : '',
        variants: variants,
      ),
    );
  }

  String optionalString(String key) =>
      snapshot[key] is String ? snapshot[key] as String : '';
  num? optionalAmount(String key) =>
      snapshot[key] is num ? snapshot[key] as num : null;

  final outletName = optionalString('outlet_name');
  return TransactionReceiptData(
    transactionId: record.localId,
    status: record.status,
    storeName: storeName,
    outletName: outletName.isEmpty ? record.outletId : outletName,
    address: optionalString('address'),
    logoUrl: optionalString('logo_url'),
    createdAt: record.createdAtLocal,
    cashierName: optionalString('cashier_name'),
    memberName: optionalString('member_name'),
    tableNumber: optionalString('table_number'),
    items: items,
    subtotal: optionalAmount('subtotal'),
    taxAmount: optionalAmount('tax_amount'),
    serviceCharge: optionalAmount('service_charge'),
    discountAmount: optionalAmount('discount_amount'),
    totalAmount: totalAmount,
    paymentMethod: paymentMethod,
    paidAmount: paidAmount,
    changeAmount: changeAmount,
    notes: optionalString('notes'),
    isOffline: record.status != 'synced',
    isOpenBill: record.transactionType == 'open_bill',
    isReconciliation: record.status == 'needs_reconciliation',
  );
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
    title: const Text('Sinkronisasi antrean'),
    content: TextField(
      controller: _controller,
      obscureText: true,
      keyboardType: TextInputType.number,
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
