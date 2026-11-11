import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawula_pos/features/transactions/data/services/admin_offline_resolution_service.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';

class AdminOfflineReconciliationPage extends StatefulWidget {
  const AdminOfflineReconciliationPage({
    super.key,
    required this.admin,
    required this.outletId,
    required this.dao,
    required this.checkoutRepository,
    required this.isOutletActive,
    required this.outletActiveStream,
    this.cashierMasterDataCache,
  });

  final AuthUser admin;
  final String outletId;
  final OfflineTransactionsDao dao;
  final CheckoutRepository checkoutRepository;
  final bool Function() isOutletActive;
  final Stream<bool> outletActiveStream;
  final CashierMasterDataCache? cashierMasterDataCache;

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
  ValueListenable<CashierNetworkStatus>? _networkStatusListenable;
  StreamSubscription<bool>? _outletActiveSubscription;
  late bool _outletActive;

  @override
  void initState() {
    super.initState();
    _outletActive = widget.isOutletActive();
    _listenToOutletStatus(widget.outletActiveStream);
    _listenToNetworkStatus(widget.cashierMasterDataCache);
  }

  @override
  void didUpdateWidget(AdminOfflineReconciliationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cashierMasterDataCache != widget.cashierMasterDataCache) {
      _networkStatusListenable?.removeListener(_onNetworkStatusChanged);
      _listenToNetworkStatus(widget.cashierMasterDataCache);
    }
    if (oldWidget.outletActiveStream != widget.outletActiveStream) {
      unawaited(_outletActiveSubscription?.cancel());
      _outletActive = widget.isOutletActive();
      _listenToOutletStatus(widget.outletActiveStream);
    }
  }

  @override
  void dispose() {
    _networkStatusListenable?.removeListener(_onNetworkStatusChanged);
    unawaited(_outletActiveSubscription?.cancel());
    _ownerController.dispose();
    super.dispose();
  }

  bool get _readOnly =>
      _currentUserIsOffline ||
      !_outletActive ||
      (widget.cashierMasterDataCache?.networkStatus ==
          CashierNetworkStatus.offline);

  bool get _currentUserIsOffline {
    final state = context.read<AuthCubit>().state;
    return state is AuthAuthenticated && state.user.isOfflineSession;
  }

  void _listenToNetworkStatus(CashierMasterDataCache? cache) {
    _networkStatusListenable = cache?.networkStatusListenable;
    _networkStatusListenable?.addListener(_onNetworkStatusChanged);
  }

  void _listenToOutletStatus(Stream<bool> stream) {
    _outletActiveSubscription = stream.listen((active) {
      if (mounted) setState(() => _outletActive = active);
    });
  }

  void _onNetworkStatusChanged() {
    if (mounted) setState(() {});
  }

  AdminOfflineResolutionService get _service => AdminOfflineResolutionService(
    dao: widget.dao,
    checkoutRepository: widget.checkoutRepository,
    verifyAdminSession: _verifyAdminSession,
  );

  Future<AuthUser?> _verifyAdminSession() async {
    if (!_outletActive || !widget.isOutletActive()) return null;
    final cubit = context.read<AuthCubit>();
    if (!await cubit.verifyCashierSession()) return null;
    final state = cubit.state;
    if (state is! AuthAuthenticated ||
        state.user.id != widget.admin.id ||
        state.user.role != 'Admin' ||
        state.user.isOfflineSession) {
      return null;
    }
    return state.user;
  }

  String _statusLabel(String status) => switch (status) {
    'pending_sync' => 'Menunggu sinkronisasi',
    'syncing' => 'Sedang disinkronkan',
    'synced' => 'Tersinkron',
    'failed' => 'Gagal',
    'needs_reconciliation' => 'Perlu rekonsiliasi',
    'resolved_manually' => 'Diselesaikan manual',
    _ => status,
  };

  num _total(OfflineTransaction record) {
    final snapshot = _snapshot(record);
    final value =
        snapshot['total_amount'] ?? snapshot['total'] ?? snapshot['amount'];
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> _snapshot(OfflineTransaction record) {
    final decoded = jsonDecode(record.receiptSnapshotJson);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  String _snapshotString(OfflineTransaction record, String key) {
    final value = _snapshot(record)[key];
    return value is String ? value : '';
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
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

  List<OfflineTransaction> _filterRecords(List<OfflineTransaction> records) {
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
      final ownerName = _snapshotString(record, 'cashier_name').toLowerCase();
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

  Future<void> _searchCandidates(OfflineTransaction record) async {
    if (_readOnly) return;
    setState(() => _isWorking = true);
    try {
      final candidates = await _service.findCandidates(
        localId: record.localId,
        activeOutletId: widget.outletId,
      );
      if (!mounted) return;
      if (candidates.isEmpty) {
        _showMessage(
          'Tidak ada kandidat yang cukup cocok pada data histori yang dikembalikan server. '
          'Ini bukan bukti transaksi tidak tersimpan; status tetap belum berubah.',
        );
        return;
      }
      final selectedId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kandidat transaksi server'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: candidates
                    .map(
                      (candidate) => ListTile(
                        title: Text(candidate.id),
                        subtitle: Text(
                          '${candidate.cashierName} · ${candidate.status} · '
                          '${candidate.createdAt == null ? 'Waktu tidak tersedia' : _formatDate(candidate.createdAt!)} · '
                          '${formatRupiah(candidate.totalAmount)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, candidate.id),
                      ),
                    )
                    .toList(growable: false),
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
      if (selectedId == null || !mounted) return;
      final candidate = candidates.singleWhere(
        (transaction) => transaction.id == selectedId,
      );
      final reason = await _confirmMatch(record, candidate);
      if (reason == null || !mounted) return;
      await _service.matchExistingRemote(
        localId: record.localId,
        activeOutletId: widget.outletId,
        remoteTransactionId: candidate.id,
        reason: reason,
      );
      if (mounted) {
        _showMessage('Transaksi ditautkan ke ID server ${candidate.id}.');
      }
    } catch (error) {
      if (mounted) _showMessage('Rekonsiliasi gagal: $error');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<String?> _confirmMatch(
    OfflineTransaction local,
    TransactionRecord remote,
  ) {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Periksa dan tautkan transaksi'),
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
                    'Waktu lokal: ${_formatDate(local.createdAtLocal)}\n'
                    'Waktu server: ${remote.createdAt == null ? 'Tidak tersedia' : _formatDate(remote.createdAt!)}\n'
                    'Kasir: ${local.ownerUserId} / ${remote.cashierId}\n'
                    'Outlet: ${local.outletId} / ${remote.outletId}\n'
                    'Total: ${formatRupiah(_total(local))} / ${formatRupiah(remote.totalAmount)}\n'
                    'Pembayaran: ${_snapshotString(local, 'payment_method')} / ${remote.paymentMethod}',
                  ),
                  const SizedBox(height: 12),
                  const Text('Snapshot lokal:'),
                  SelectableText(
                    const JsonEncoder.withIndent('  ')
                        .convert(_snapshot(local)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Transaksi server:'),
                  SelectableText(
                    const JsonEncoder.withIndent('  ')
                        .convert(_remoteAsJson(remote)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Alasan keputusan Admin (wajib)',
                    ),
                    minLines: 2,
                    maxLines: 4,
                    onChanged: (_) => setDialogState(() {}),
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
              onPressed: reasonController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, reasonController.text.trim()),
              child: const Text('Tautkan transaksi'),
            ),
          ],
        ),
      ),
    ).whenComplete(reasonController.dispose);
  }

  Future<void> _handleFailedOutsideServer(OfflineTransaction record) async {
    if (_readOnly) return;
    final reason = await _requestReason(
      title: 'Tandai ditangani di luar sistem',
      message: 'Tindakan ini hanya untuk penolakan server yang pasti. Transaksi tidak dianggap tersinkron dan tidak dihapus.',
    );
    if (reason == null || !mounted) return;
    setState(() => _isWorking = true);
    try {
      await _service.handleFailedOutsideServer(
        localId: record.localId,
        activeOutletId: widget.outletId,
        reason: reason,
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

  Future<String?> _requestReason({
    required String title,
    required String message,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Alasan keputusan Admin (wajib)',
                ),
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _showDetail(OfflineTransaction record) async {
    final audit = await widget.dao.getResolutionAudit(record.localId);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.localId),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kasir: ${_snapshotString(record, 'cashier_name')}'),
                Text('User ID: ${record.ownerUserId}'),
                Text(
                  'Outlet: ${_snapshotString(record, 'outlet_name')} (${record.outletId})',
                ),
                Text('Shift asal: ${record.shiftId}'),
                Text('Waktu lokal: ${_formatDate(record.createdAtLocal)}'),
                Text('Total: ${formatRupiah(_total(record))}'),
                Text(
                  'Metode pembayaran: ${_snapshotString(record, 'payment_method')}',
                ),
                Text('Jenis transaksi: ${record.transactionType}'),
                Text('Status: ${_statusLabel(record.status)}'),
                if (record.remoteTransactionId != null)
                  Text('ID transaksi server: ${record.remoteTransactionId}'),
                if (record.status == 'resolved_manually' &&
                    record.remoteTransactionId == null)
                  const Text('Transaksi tidak tersinkron ke server.'),
                if (record.lastError != null)
                  Text('Alasan gagal: ${record.lastError}'),
                const SizedBox(height: 12),
                const Text('Snapshot struk:'),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(_snapshot(record)),
                ),
                if (audit.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Audit penyelesaian:'),
                  for (final entry in audit)
                    Text(
                      '${entry.resolutionType} · Admin ${entry.resolvingAdminUserId} '
                      '(${entry.resolvingAdminRole}) · ${_formatDate(entry.resolvedAt)}\n'
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
        appBar: AppBar(title: const Text('Rekonsiliasi transaksi offline')),
        body: const Center(child: Text('Akses outlet aktif tidak tersedia.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rekonsiliasi transaksi offline')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Daftar hanya mencakup database perangkat ini dan outlet aktif. '
              'Pencarian server memakai histori yang dikembalikan GET /transactions; '
              'endpoint ini tidak menyediakan filter atau pagination pada aplikasi.',
            ),
          ),
          if (_readOnly)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Mode hanya-baca: verifikasi Admin online diperlukan untuk tindakan rekonsiliasi.',
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
                            child: Text('Perlu rekonsiliasi'),
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
            child: StreamBuilder<List<OfflineTransaction>>(
              stream: widget.dao.watchTransactionsByOutletLatest(
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
                  snapshot.data ?? const <OfflineTransaction>[],
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
                    final cashier = _snapshotString(record, 'cashier_name');
                    return Card(
                      child: ListTile(
                        title: Text(
                          '${record.localId} · ${_statusLabel(record.status)}',
                        ),
                        subtitle: Text(
                          '${cashier.isEmpty ? record.ownerUserId : cashier} · '
                          '${_formatDate(record.createdAtLocal)} · '
                          '${formatRupiah(_total(record))} · ${record.transactionType}',
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
                                child: Text('Cari kandidat server'),
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

Map<String, Object?> _remoteAsJson(TransactionRecord transaction) => {
  'id': transaction.id,
  'status': transaction.status,
  'outlet_id': transaction.outletId,
  'created_by': transaction.cashierId,
  'created_at': transaction.createdAt?.toIso8601String(),
  'total_amount': transaction.totalAmount,
  'payment_method': transaction.paymentMethod,
  'items': transaction.items
      .map(
        (item) => {
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'price': item.price,
          'selected_variants': item.selectedVariants
              .map(
                (variant) => {
                  'group_name': variant.groupName,
                  'option_name': variant.optionName,
                },
              )
              .toList(growable: false),
        },
      )
      .toList(growable: false),
};
