import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/transactions/data/services/offline_transaction_sync_service.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

class OfflineTransactionQueuePage extends StatefulWidget {
  const OfflineTransactionQueuePage({
    super.key,
    required this.user,
    required this.outletId,
    required this.shiftId,
    required this.dao,
    required this.syncService,
    this.offlineMasterDataCache,
  });

  final AuthUser user;
  final String outletId;
  final String shiftId;
  final OfflineTransactionsDao dao;
  final OfflineTransactionSyncService syncService;
  final OfflineMasterDataCache? offlineMasterDataCache;

  @override
  State<OfflineTransactionQueuePage> createState() =>
      _OfflineTransactionQueuePageState();
}

class _OfflineTransactionQueuePageState
    extends State<OfflineTransactionQueuePage> {
  bool _isSyncFlowActive = false;
  String _selectedStatus = 'all';
  ValueListenable<OfflineNetworkStatus>? _networkStatusListenable;

  @override
  void initState() {
    super.initState();
    _listenToNetworkStatus(widget.offlineMasterDataCache);
  }

  @override
  void didUpdateWidget(OfflineTransactionQueuePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offlineMasterDataCache != widget.offlineMasterDataCache) {
      _networkStatusListenable?.removeListener(_onNetworkStatusChanged);
      _listenToNetworkStatus(widget.offlineMasterDataCache);
    }
  }

  @override
  void dispose() {
    _networkStatusListenable?.removeListener(_onNetworkStatusChanged);
    super.dispose();
  }

  void _listenToNetworkStatus(OfflineMasterDataCache? cache) {
    _networkStatusListenable = cache?.networkStatusListenable;
    _networkStatusListenable?.addListener(_onNetworkStatusChanged);
  }

  void _onNetworkStatusChanged() {
    if (mounted) setState(() {});
  }

  OfflineNetworkStatus get _networkStatus =>
      _networkStatusListenable?.value ?? OfflineNetworkStatus.offline;

  String _statusLabel(String status) {
    return switch (status) {
      'pending_sync' => 'Menunggu',
      'syncing' => 'Menyinkron',
      'synced' => 'Tersinkron',
      'failed' => 'Gagal',
      'needs_reconciliation' => 'Rekonsiliasi',
      'resolved_manually' => 'Diselesaikan manual',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending_sync' => Colors.orange,
      'syncing' => Colors.blue,
      'synced' => Colors.green,
      'failed' => Colors.red,
      'needs_reconciliation' => Colors.purple,
      'resolved_manually' => Colors.blueGrey,
      _ => Colors.grey,
    };
  }

  num _extractAmount(OfflineTransaction record) {
    try {
      final parsed = jsonDecode(record.receiptSnapshotJson);
      if (parsed is! Map<String, dynamic>) {
        return 0;
      }
      final total =
          parsed['total_amount'] ?? parsed['total'] ?? parsed['amount'];
      if (total is num) return total;
      if (total is String) return num.tryParse(total) ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  String _formatCreatedAt(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }

  Future<void> _syncQueue() async {
    if (_isSyncFlowActive || widget.syncService.isSyncing) return;
    setState(() => _isSyncFlowActive = true);
    try {
      final pin = await showDialog<String>(
        context: context,
        builder: (_) => const _PinEntryDialog(),
      );
      if (!mounted || pin == null || pin.isEmpty) return;

      final summary = await widget.syncService.syncOfflineTransactions(
        ownerUserId: widget.user.id,
        outletId: widget.outletId,
        role: widget.user.role,
        pin: pin,
      );
      if (!mounted) return;
      final reason = summary.stopReason ?? 'Proses selesai.';
      final resultCounts =
          '${summary.successCount} berhasil, '
          '${summary.failedCount} gagal pada proses ini, '
          '${summary.existingFailedCount} gagal sebelumnya, '
          '${summary.pendingCount} pending, '
          '${summary.needsReconciliationCount} perlu rekonsiliasi '
          '(${summary.unresolvedCount} belum selesai).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            summary.stopped
                ? 'Sinkronisasi dihentikan: $reason $resultCounts'
                : 'Selesai. $resultCounts',
          ),
        ),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sinkronisasi gagal: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSyncFlowActive = false);
      }
    }
  }

  Future<void> _showTransactionDetail(OfflineTransaction record) async {
    final data = jsonDecode(record.receiptSnapshotJson);
    final text = const JsonEncoder.withIndent('  ').convert(data);
    final audit = await widget.dao.getResolutionAudit(record.localId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.localId),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${_statusLabel(record.status)}'),
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
                SelectableText(text),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!canUseOfflineSales(widget.user.role)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Antrean Offline')),
        body: const Center(
          child: Text('Role ini tidak memiliki akses Offline Sales.'),
        ),
      );
    }
    final canSyncOnline = _networkStatus == OfflineNetworkStatus.online;
    return StreamBuilder<List<OfflineTransaction>>(
      stream: widget.dao.watchTransactionsByOwnerLatest(widget.user.id),
      builder: (context, snapshot) {
        final allTransactions = (snapshot.data ?? const <OfflineTransaction>[])
            .where((record) => record.outletId == widget.outletId)
            .toList(growable: false);
        final queue = _selectedStatus == 'all'
            ? allTransactions
            : allTransactions
                  .where((record) => record.status == _selectedStatus)
                  .toList(growable: false);
        final shiftQueue = allTransactions
            .where(
              (record) =>
                  record.outletId == widget.outletId &&
                  record.shiftId == widget.shiftId &&
                  OfflineTransactionsDao.unresolvedStatuses.contains(
                    record.status,
                  ),
            )
            .toList(growable: false);
        final pendingSyncCount = allTransactions
            .where(
              (record) =>
                  record.outletId == widget.outletId &&
                  record.status ==
                      OfflineTransactionStatus.pendingSync.databaseValue,
            )
            .length;
        final pendingCount = shiftQueue
            .where((r) => r.status == 'pending_sync')
            .length;
        final syncingCount = shiftQueue
            .where((r) => r.status == 'syncing')
            .length;
        final failedCount = shiftQueue
            .where((r) => r.status == 'failed')
            .length;
        final needsCount = shiftQueue
            .where((r) => r.status == 'needs_reconciliation')
            .length;
        final syncedCount = queue.where((r) => r.status == 'synced').length;

        return Scaffold(
          appBar: AppBar(title: const Text('Antrean Offline')),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
              ? Center(child: Text('Gagal memuat antrean: ${snapshot.error}'))
              : Column(
                  children: [
                    Padding(
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
                                count: pendingCount,
                                color: Colors.orange,
                              ),
                              _SummaryChip(
                                label: 'Sedang disinkronkan',
                                count: syncingCount,
                                color: Colors.blue,
                              ),
                              _SummaryChip(
                                label: 'Gagal',
                                count: failedCount,
                                color: Colors.red,
                              ),
                              _SummaryChip(
                                label: 'Rekonsiliasi',
                                count: needsCount,
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
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Filter status',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Semua status'),
                          ),
                          DropdownMenuItem(
                            value: 'pending_sync',
                            child: Text('Menunggu'),
                          ),
                          DropdownMenuItem(
                            value: 'syncing',
                            child: Text('Menyinkron'),
                          ),
                          DropdownMenuItem(
                            value: 'synced',
                            child: Text('Tersinkron'),
                          ),
                          DropdownMenuItem(
                            value: 'failed',
                            child: Text('Gagal'),
                          ),
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
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: queue.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Belum ada transaksi offline.'),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                0,
                                12,
                                112,
                              ),
                              itemCount: queue.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final record = queue[index];
                                final status = record.status;
                                final amount = _extractAmount(record);
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      '${record.localId} · ${record.transactionType.toUpperCase()}',
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_formatCreatedAt(record.createdAtLocal)} · ${formatRupiah(amount)}',
                                        ),
                                        if (record.lastError != null &&
                                            record.lastError!.isNotEmpty)
                                          Text(
                                            record.lastError!,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Chip(
                                      label: Text(_statusLabel(status)),
                                      backgroundColor: _statusColor(status)
                                          .withValues(alpha: 0.15),
                                      side: BorderSide(
                                        color: _statusColor(status)
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    onTap: () => _showTransactionDetail(record),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
          floatingActionButton: pendingSyncCount == 0
              ? null
              : FloatingActionButton.extended(
                  onPressed:
                      !canSyncOnline ||
                          _isSyncFlowActive ||
                          widget.syncService.isSyncing
                      ? null
                      : _syncQueue,
                  icon: _isSyncFlowActive || widget.syncService.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sinkronkan Antrean'),
                      const SizedBox(width: 8),
                      _PendingCountBadge(count: pendingSyncCount),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _PinEntryDialog extends StatefulWidget {
  const _PinEntryDialog();

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.clear();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text('$label: $count'),
    );
  }
}

class _PendingCountBadge extends StatelessWidget {
  const _PendingCountBadge({required this.count});

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
