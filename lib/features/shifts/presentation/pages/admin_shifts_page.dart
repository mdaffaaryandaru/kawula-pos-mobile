import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transactions/domain/entities/checkout.dart';
import '../../domain/entities/active_shift.dart';
import '../../domain/entities/admin_shift_detail.dart';
import '../../domain/repositories/admin_shifts_repository.dart';
import '../bloc/admin_shifts_cubit.dart';

class AdminShiftsPage extends StatelessWidget {
  const AdminShiftsPage({super.key, required this.repository});

  final AdminShiftsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminShiftsCubit(repository)..load(),
      child: BlocBuilder<AdminShiftsCubit, AdminShiftsState>(
        builder: (context, state) => switch (state) {
          AdminShiftsLoading() => const Scaffold(
            appBar: _AdminShiftsAppBar(),
            body: Center(child: CircularProgressIndicator()),
          ),
          AdminShiftsFailure() => Scaffold(
            appBar: const _AdminShiftsAppBar(),
            body: _loadFailure(context, state.message),
          ),
          AdminShiftsLoaded() => _shiftList(context, state),
        },
      ),
    );
  }

  Widget _loadFailure(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Daftar shift belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<AdminShiftsCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftList(BuildContext context, AdminShiftsLoaded state) {
    final openShiftCount = state.shifts
        .where((shift) => shift.status == 'open')
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const _ShiftLogoTitle(title: 'Shift kasir'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => context.read<AdminShiftsCubit>().load(
              status: state.statusFilter,
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: state.statusFilter ?? 'all',
              decoration: const InputDecoration(
                labelText: 'Filter status',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua shift')),
                DropdownMenuItem(value: 'open', child: Text('Sedang berjalan')),
                DropdownMenuItem(
                  value: 'closed',
                  child: Text('Ditutup manual'),
                ),
                DropdownMenuItem(
                  value: 'auto_closed',
                  child: Text('Ditutup otomatis'),
                ),
              ],
              onChanged: (value) => context.read<AdminShiftsCubit>().load(
                status: value == null || value == 'all' ? null : value,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _ShiftListSummary(
              shiftCount: state.shifts.length,
              openShiftCount: openShiftCount,
            ),
          ),
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => context.read<AdminShiftsCubit>().load(
                    status: state.statusFilter,
                  ),
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<AdminShiftsCubit>().load(
                status: state.statusFilter,
              ),
              child: state.shifts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Tidak ada shift pada filter ini.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.shifts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final shift = state.shifts[index];
                        return _ShiftCard(
                          shift: shift,
                          onTap: () async {
                            final changed = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => AdminShiftDetailPage(
                                      shiftId: shift.id,
                                      repository: repository,
                                    ),
                                  ),
                                );
                            if (context.mounted && changed == true) {
                              await context.read<AdminShiftsCubit>().load(
                                status: state.statusFilter,
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminShiftsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AdminShiftsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const _ShiftLogoTitle(title: 'Shift kasir'));
}

class _ShiftLogoTitle extends StatelessWidget {
  const _ShiftLogoTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text(title),
      ],
    );
  }
}

class _ShiftListSummary extends StatelessWidget {
  const _ShiftListSummary({
    required this.shiftCount,
    required this.openShiftCount,
  });

  final int shiftCount;
  final int openShiftCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: const Icon(Icons.schedule_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$shiftCount shift ditemukan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$openShiftCount sedang berjalan · mengikuti filter',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$openShiftCount aktif',
                style: const TextStyle(
                  color: Color(0xFF16834A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift, required this.onTap});

  final ActiveShift shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Text(_initials(shift.cashierName ?? 'Kasir')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.cashierName ?? 'Kasir',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (shift.cashierEmail != null)
                          Text(
                            shift.cashierEmail!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ShiftStatusChip(status: shift.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shift.outletName ?? 'Outlet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.schedule_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(_dateTime(shift.startTime)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ShiftCardMetric(
                      label: 'Modal awal',
                      value: _rupiah(shift.startingCash),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShiftCardMetric(
                      label: 'Penjualan',
                      value: _rupiah(shift.totalSales),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('${shift.totalTransactions} transaksi'),
                  const Spacer(),
                  Text(
                    'Detail',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftCardMetric extends StatelessWidget {
  const _ShiftCardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ShiftStatusChip extends StatelessWidget {
  const _ShiftStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'open';
    final color = isOpen
        ? const Color(0xFF16834A)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _shiftStatus(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class AdminShiftDetailPage extends StatefulWidget {
  const AdminShiftDetailPage({
    super.key,
    required this.shiftId,
    required this.repository,
  });

  final String shiftId;
  final AdminShiftsRepository repository;

  @override
  State<AdminShiftDetailPage> createState() => _AdminShiftDetailPageState();
}

class _AdminShiftDetailPageState extends State<AdminShiftDetailPage> {
  late Future<AdminShiftDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.getShiftDetail(widget.shiftId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const _ShiftLogoTitle(title: 'Detail shift')),
      body: FutureBuilder<AdminShiftDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detail shift gagal dimuat: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _detail = widget.repository.getShiftDetail(
                            widget.shiftId,
                          );
                        });
                      },
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          final detail = snapshot.data!;
          return _detailBody(detail);
        },
      ),
    );
  }

  Widget _detailBody(AdminShiftDetail detail) {
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
                      value: _rupiah(shift.totalSales),
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
                        value: _rupiah(shift.startingCash),
                      ),
                      _ShiftValue(
                        label: 'Kas yang diharapkan',
                        value: _rupiah(shift.expectedCash),
                      ),
                      if (shift.actualCash != null)
                        _ShiftValue(
                          label: 'Kas aktual',
                          value: _rupiah(shift.actualCash!),
                        ),
                      if (shift.cashDifference != null)
                        _ShiftValue(
                          label: 'Selisih kas',
                          value: _rupiah(shift.cashDifference!),
                          valueColor: shift.cashDifference == 0
                              ? const Color(0xFF16834A)
                              : Theme.of(context).colorScheme.error,
                        ),
                      const Divider(height: 24),
                      _ShiftValue(
                        label: 'Total penjualan',
                        value: _rupiah(shift.totalSales),
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
                  onPressed: () => _forceClose(shift),
                  icon: const Icon(Icons.lock_clock_outlined),
                  label: const Text('Paksa tutup shift'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _forceClose(ActiveShift shift) async {
    final draft = await showDialog<_ForceCloseDraft>(
      context: context,
      builder: (_) => _ForceCloseDialog(shift: shift),
    );
    if (draft == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi force close'),
        content: Text(
          'Kas diharapkan ${_rupiah(shift.expectedCash)}.\n'
          'Kas aktual ${_rupiah(draft.actualCash)}.\n'
          'Perkiraan selisih ${_rupiah(draft.actualCash - shift.expectedCash)}.\n\n'
          'Shift kasir akan ditutup menggunakan nilai aktual ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tutup shift'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.forceCloseShift(
        shiftId: shift.id,
        actualCash: draft.actualCash,
        notes: draft.notes,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Force close gagal: $error')));
    }
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
                  child: Text(_initials(shift.cashierName ?? 'Kasir')),
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
            _ShiftValue(label: 'Mulai', value: _dateTime(shift.startTime)),
            _ShiftValue(
              label: 'Selesai',
              value: shift.endTime == null
                  ? 'Belum selesai'
                  : _dateTime(shift.endTime!),
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
                  _rupiah(transaction.totalAmount),
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${transaction.paymentMethod} · ${_dateTime(transaction.createdAt)}',
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

class _ForceCloseDialog extends StatefulWidget {
  const _ForceCloseDialog({required this.shift});

  final ActiveShift shift;

  @override
  State<_ForceCloseDialog> createState() => _ForceCloseDialogState();
}

class _ForceCloseDialogState extends State<_ForceCloseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _actualCashController;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _actualCashController = TextEditingController(
      text: widget.shift.expectedCash.toString(),
    );
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paksa tutup shift'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kas yang diharapkan: ${_rupiah(widget.shift.expectedCash)}'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _actualCashController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Kas aktual',
                prefixText: 'Rp ',
              ),
              validator: (value) {
                final number = num.tryParse(value ?? '');
                return number == null || !number.isFinite || number < 0
                    ? 'Masukkan kas aktual yang valid.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan force close',
              ),
              maxLines: 2,
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Catatan penutupan wajib diisi.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _ForceCloseDraft(
                actualCash: num.parse(_actualCashController.text),
                notes: _notesController.text.trim(),
              ),
            );
          },
          child: const Text('Lanjut'),
        ),
      ],
    );
  }
}

class _ForceCloseDraft {
  const _ForceCloseDraft({required this.actualCash, required this.notes});

  final num actualCash;
  final String notes;
}

String _shiftStatus(String status) => switch (status) {
  'open' => 'Sedang berjalan',
  'closed' => 'Ditutup manual',
  'auto_closed' => 'Ditutup otomatis',
  _ => status,
};

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList(growable: false);
  if (parts.isEmpty) return 'K';
  return parts.map((part) => part[0].toUpperCase()).join();
}

String _rupiah(num amount) {
  final digits = amount.abs().toInt().toString();
  final result = StringBuffer(amount < 0 ? '-Rp ' : 'Rp ');
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  return result.toString();
}

String _dateTime(DateTime? value) {
  if (value == null) return 'Waktu tidak tersedia';
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
