import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawula_pos/features/offline/domain/services/offline_network_status_controller.dart';
import 'package:kawula_pos/features/offline/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/offline/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/features/offline/domain/services/offline_transaction_reconciliation.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/offline/presentation/widgets/offline_transaction_formatters.dart';
import 'package:kawula_pos/features/offline/presentation/widgets/offline_transaction_reconciliation_widgets.dart';

class AdminOfflineReconciliationPage extends StatefulWidget {
  const AdminOfflineReconciliationPage({
    super.key,
    required this.admin,
    required this.outletId,
    required this.queueRepository,
    required this.reconciliation,
    required this.isOutletActive,
    required this.outletActiveStream,
    this.offlineNetworkStatusController,
  });

  final AuthUser admin;
  final String outletId;
  final OfflineTransactionQueueRepository queueRepository;
  final OfflineTransactionReconciliation reconciliation;
  final bool Function() isOutletActive;
  final Stream<bool> outletActiveStream;
  final OfflineNetworkStatusController? offlineNetworkStatusController;

  @override
  State<AdminOfflineReconciliationPage> createState() =>
      _AdminOfflineReconciliationPageState();
}

class _AdminOfflineReconciliationPageState
    extends State<AdminOfflineReconciliationPage> {
  final _ownerController = TextEditingController();
  String _statusFilter = 'unresolved';
  DateTimeRange? _dateRange;
  bool _isWorking = false;
  OfflineNetworkStatus _networkStatus = OfflineNetworkStatus.online;
  StreamSubscription<OfflineNetworkStatus>? _networkStatusSubscription;
  StreamSubscription<bool>? _outletActiveSubscription;
  late bool _outletActive;

  @override
  void initState() {
    super.initState();
    _outletActive = widget.isOutletActive();
    _listenToOutletStatus(widget.outletActiveStream);
    _listenToNetworkStatus(widget.offlineNetworkStatusController);
  }

  @override
  void didUpdateWidget(AdminOfflineReconciliationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offlineNetworkStatusController !=
        widget.offlineNetworkStatusController) {
      unawaited(_networkStatusSubscription?.cancel());
      _listenToNetworkStatus(widget.offlineNetworkStatusController);
    }
    if (oldWidget.outletActiveStream != widget.outletActiveStream) {
      unawaited(_outletActiveSubscription?.cancel());
      _outletActive = widget.isOutletActive();
      _listenToOutletStatus(widget.outletActiveStream);
    }
  }

  @override
  void dispose() {
    unawaited(_networkStatusSubscription?.cancel());
    unawaited(_outletActiveSubscription?.cancel());
    _ownerController.dispose();
    super.dispose();
  }

  bool get _readOnly =>
      _currentUserIsOffline ||
      !_outletActive ||
      _networkStatus == OfflineNetworkStatus.offline;

  bool get _currentUserIsOffline {
    final state = context.read<AuthCubit>().state;
    return state is AuthAuthenticated && state.user.isOfflineSession;
  }

  void _listenToNetworkStatus(
    OfflineNetworkStatusController? networkStatusController,
  ) {
    _networkStatus =
        networkStatusController?.status ?? OfflineNetworkStatus.online;
    _networkStatusSubscription = networkStatusController?.statusChanges.listen(
      _onNetworkStatusChanged,
    );
  }

  void _listenToOutletStatus(Stream<bool> stream) {
    _outletActiveSubscription = stream.listen((active) {
      if (mounted) setState(() => _outletActive = active);
    });
  }

  void _onNetworkStatusChanged(OfflineNetworkStatus status) {
    if (mounted) setState(() => _networkStatus = status);
  }

  Future<AuthUser?> _verifyAdminSession() async {
    if (!_outletActive || !widget.isOutletActive()) return null;
    final cubit = context.read<AuthCubit>();
    if (!await cubit.verifyOfflineSalesSession()) return null;
    final state = cubit.state;
    if (state is! AuthAuthenticated ||
        state.user.id != widget.admin.id ||
        state.user.role != 'Admin' ||
        state.user.isOfflineSession) {
      return null;
    }
    return state.user;
  }

  int _statusPriority(String status) => switch (status) {
    'needs_reconciliation' => 0,
    'failed' => 1,
    'pending_sync' => 2,
    'syncing' => 3,
    'resolved_manually' => 4,
    'synced' => 5,
    _ => 6,
  };

  List<OfflineTransactionQueueItem> _filterRecords(
    List<OfflineTransactionQueueItem> records,
  ) {
    final ownerQuery = _ownerController.text.trim().toLowerCase();
    final filtered = records.where((record) {
      if (_statusFilter == 'unresolved' &&
          record.status != 'failed' &&
          record.status != 'needs_reconciliation') {
        return false;
      }
      if (_statusFilter != 'all' &&
          _statusFilter != 'unresolved' &&
          record.status != _statusFilter) {
        return false;
      }
      final ownerName = offlineReceiptField(
        record,
        'cashier_name',
      ).toLowerCase();
      if (ownerQuery.isNotEmpty &&
          !record.ownerUserId.toLowerCase().contains(ownerQuery) &&
          !ownerName.contains(ownerQuery)) {
        return false;
      }
      final range = _dateRange;
      if (range != null) {
        final date = record.createdAtLocal;
        if (date.isBefore(range.start) ||
            date.isAfter(
              DateTime(
                range.end.year,
                range.end.month,
                range.end.day,
                23,
                59,
                59,
                999,
              ),
            )) {
          return false;
        }
      }
      return true;
    }).toList();
    filtered.sort((a, b) {
      final statusOrder = _statusPriority(a.status)
          .compareTo(_statusPriority(b.status));
      if (statusOrder != 0) return statusOrder;
      return b.createdAtLocal.compareTo(a.createdAtLocal);
    });
    return filtered;
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (selected != null && mounted) {
      setState(() => _dateRange = selected);
    }
  }

  Future<void> _searchCandidates(OfflineTransactionQueueItem record) async {
    if (_readOnly) return;
    setState(() => _isWorking = true);
    try {
      final candidates = await widget.reconciliation.findCandidates(
        localId: record.localId,
        activeOutletId: widget.outletId,
        verifyAdminSession: _verifyAdminSession,
      );
      if (!mounted) return;
      if (candidates.isEmpty) {
        _showMessage(
          'Tidak ada kandidat yang cukup cocok pada data histori yang dikembalikan server. '
          'Ini bukan bukti transaksi tidak tersimpan; status tetap belum berubah.',
        );
        return;
      }
      final selectedId = await showReconciliationCandidateDialog(
        context,
        candidates,
        localCreatedAt: record.createdAtLocal,
      );
      if (selectedId == null || !mounted) return;
      final candidate = candidates.singleWhere(
        (transaction) => transaction.id == selectedId,
      );
      final reason = await showReconciliationMatchDialog(
        context,
        local: record,
        remote: candidate,
      );
      if (reason == null || !mounted) return;
      await widget.reconciliation.matchExistingRemote(
        localId: record.localId,
        activeOutletId: widget.outletId,
        remoteTransactionId: candidate.id,
        reason: reason,
        verifyAdminSession: _verifyAdminSession,
      );
      if (mounted) {
        _showMessage('Transaksi ditautkan ke ID server ${candidate.id}.');
      }
    } catch (error) {
      if (mounted) _showMessage('pencocokan gagal: $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _handleFailedOutsideServer(
    OfflineTransactionQueueItem record,
  ) async {
    if (_readOnly) return;
    final reason = await showReconciliationReasonDialog(
      context,
      title: 'Tandai ditangani di luar sistem',
      message: 'Tindakan ini hanya untuk penolakan server yang pasti. Transaksi tidak dianggap tersinkron dan tidak dihapus.',
    );
    if (reason == null || !mounted) return;
    setState(() => _isWorking = true);
    try {
      await widget.reconciliation.handleFailedOutsideServer(
        localId: record.localId,
        activeOutletId: widget.outletId,
        reason: reason,
        verifyAdminSession: _verifyAdminSession,
      );
      if (mounted) {
        _showMessage(
          'Transaksi ditandai ditangani di luar sistem; tidak tersinkron ke server.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage('Penyelesaian gagal: $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _showDetail(OfflineTransactionQueueItem record) async {
    final audit = await widget.queueRepository.getResolutionAudit(
      record.localId,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => OfflineReconciliationTransactionDetailDialog(
        record: record,
        audit: audit,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (widget.admin.role != 'Admin' ||
        widget.outletId.trim().isEmpty ||
        !_outletActive ||
        !widget.isOutletActive() ||
        authState is! AuthAuthenticated ||
        authState.user.id != widget.admin.id ||
        authState.user.role != 'Admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Pencocokan transaksi offline')),
        body: const Center(child: Text('Akses outlet aktif tidak tersedia.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pencocokan transaksi offline')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Pencarian hanya mencakup transaksi terbaru yang dikembalikan server.',
            ),
          ),
          if (_readOnly)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Mode hanya-baca: verifikasi Admin online diperlukan untuk tindakan pencocokan.',
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _ownerController,
                  decoration: InputDecoration(
                    labelText: 'Cari pemilik (nama atau user ID)',
                    prefixIcon: const Icon(Icons.person_search),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.search),
                    ),
                  ),
                  onSubmitted: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter status',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'unresolved',
                            child: Text('Perlu penanganan'),
                          ),
                          DropdownMenuItem(
                            value: 'failed',
                            child: Text('Gagal'),
                          ),
                          DropdownMenuItem(
                            value: 'needs_reconciliation',
                            child: Text('Perlu pencocokan'),
                          ),
                          DropdownMenuItem(
                            value: 'resolved_manually',
                            child: Text('Diselesaikan manual'),
                          ),
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Semua status'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _statusFilter = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: _dateRange == null
                          ? 'Filter waktu'
                          : 'Hapus filter waktu',
                      onPressed: _dateRange == null
                          ? _selectDateRange
                          : () => setState(() => _dateRange = null),
                      icon: Icon(
                        _dateRange == null
                            ? Icons.date_range
                            : Icons.event_busy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isWorking) const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<List<OfflineTransactionQueueItem>>(
              stream: widget.queueRepository.watchTransactionsByOutletLatest(
                widget.outletId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat antrean: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = _filterRecords(
                  snapshot.data ?? const <OfflineTransactionQueueItem>[],
                );
                if (records.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada transaksi pada filter ini.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: records.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final cashier = offlineReceiptField(record, 'cashier_name');
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${record.localId} · ${offlineReconciliationStatusLabel(record.status)}',
                        ),
                        subtitle: Text(
                          '${cashier.isEmpty ? record.ownerUserId : cashier} · '
                          '${formatOfflineTransactionDate(record.createdAtLocal)} · '
                          '${formatRupiah(offlineReceiptTotal(record))} · ${record.transactionType}',
                        ),
                        trailing: PopupMenuButton<String>(
                          enabled: !_isWorking && !_readOnly,
                          onSelected: (action) {
                            if (action == 'detail') {
                              _showDetail(record);
                            } else if (action == 'search') {
                              _searchCandidates(record);
                            } else if (action == 'outside') {
                              _handleFailedOutsideServer(record);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'detail',
                              child: Text('Detail dan audit'),
                            ),
                            if (record.status == 'failed' ||
                                record.status == 'needs_reconciliation')
                              const PopupMenuItem(
                                value: 'search',
                                child: Text('Cari transaksi di sistem'),
                              ),
                            if (record.status == 'failed')
                              const PopupMenuItem(
                                value: 'outside',
                                child: Text('Tangani di luar sistem'),
                              ),
                          ],
                        ),
                        onTap: () => _showDetail(record),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
