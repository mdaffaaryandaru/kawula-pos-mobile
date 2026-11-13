import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/offline/domain/services/offline_network_status_controller.dart';
import 'package:kawula_pos/features/offline/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/offline/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/features/offline/domain/services/offline_transaction_sync.dart';
import 'package:kawula_pos/features/offline/presentation/widgets/offline_transaction_queue_widgets.dart';
import 'package:kawula_pos/features/offline/domain/policies/offline_sales_policy.dart';

class OfflineTransactionQueuePage extends StatefulWidget {
  const OfflineTransactionQueuePage({
    super.key,
    required this.user,
    required this.outletId,
    required this.shiftId,
    required this.queueRepository,
    required this.syncService,
    this.offlineNetworkStatusController,
  });

  final AuthUser user;
  final String outletId;
  final String shiftId;
  final OfflineTransactionQueueRepository queueRepository;
  final OfflineTransactionSync syncService;
  final OfflineNetworkStatusController? offlineNetworkStatusController;

  @override
  State<OfflineTransactionQueuePage> createState() =>
      _OfflineTransactionQueuePageState();
}

class _OfflineTransactionQueuePageState
    extends State<OfflineTransactionQueuePage> {
  bool _isSyncFlowActive = false;
  String _selectedStatus = 'all';
  OfflineNetworkStatus _networkStatus = OfflineNetworkStatus.offline;
  StreamSubscription<OfflineNetworkStatus>? _networkStatusSubscription;

  @override
  void initState() {
    super.initState();
    _listenToNetworkStatus(widget.offlineNetworkStatusController);
  }

  @override
  void didUpdateWidget(OfflineTransactionQueuePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offlineNetworkStatusController !=
        widget.offlineNetworkStatusController) {
      unawaited(_networkStatusSubscription?.cancel());
      _listenToNetworkStatus(widget.offlineNetworkStatusController);
    }
  }

  @override
  void dispose() {
    unawaited(_networkStatusSubscription?.cancel());
    super.dispose();
  }

  void _listenToNetworkStatus(
    OfflineNetworkStatusController? networkStatusController,
  ) {
    _networkStatus =
        networkStatusController?.status ?? OfflineNetworkStatus.offline;
    _networkStatusSubscription = networkStatusController?.statusChanges.listen(
      _onNetworkStatusChanged,
    );
  }

  void _onNetworkStatusChanged(OfflineNetworkStatus status) {
    if (mounted) setState(() => _networkStatus = status);
  }

  Future<void> _syncQueue() async {
    if (_isSyncFlowActive || widget.syncService.isSyncing) return;
    setState(() => _isSyncFlowActive = true);
    try {
      final pin = await showDialog<String>(
        context: context,
        builder: (_) => const OfflineQueuePinDialog(),
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
          '${summary.needsReconciliationCount} perlu pencocokan, '
          '(${summary.unresolvedCount} belum selesai).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            summary.stopped
                ? 'Pengiriman data dihentikan: $reason $resultCounts'
                : 'Selesai. $resultCounts',
          ),
        ),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pengiriman data gagal: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSyncFlowActive = false);
      }
    }
  }

  Future<void> _showTransactionDetail(
    OfflineTransactionQueueItem record,
  ) async {
    final audit = await widget.queueRepository.getResolutionAudit(
      record.localId,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) =>
          OfflineQueueTransactionDetailDialog(record: record, audit: audit),
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
    return StreamBuilder<List<OfflineTransactionQueueItem>>(
      stream: widget.queueRepository.watchTransactionsByOwnerLatest(
        widget.user.id,
      ),
      builder: (context, snapshot) {
        final allTransactions =
            (snapshot.data ?? const <OfflineTransactionQueueItem>[])
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
                  offlineTransactionUnresolvedStatuses.contains(record.status),
            )
            .toList(growable: false);
        final pendingSyncCount = allTransactions
            .where(
              (record) =>
                  record.outletId == widget.outletId &&
                  record.status == 'pending_sync',
            )
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
                    OfflineQueueSummary(
                      shiftTransactions: shiftQueue,
                      syncedCount: syncedCount,
                    ),
                    OfflineQueueStatusFilter(
                      selectedStatus: _selectedStatus,
                      onChanged: (value) =>
                          setState(() => _selectedStatus = value),
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
                                return OfflineQueueTransactionTile(
                                  record: record,
                                  onTap: () => _showTransactionDetail(record),
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
                      OfflineQueuePendingCountBadge(count: pendingSyncCount),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
