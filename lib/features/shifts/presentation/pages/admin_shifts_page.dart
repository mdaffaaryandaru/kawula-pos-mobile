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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift kasir'),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: DropdownButtonFormField<String>(
              initialValue: state.statusFilter ?? 'all',
              decoration: const InputDecoration(labelText: 'Filter status'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua shift')),
                DropdownMenuItem(value: 'open', child: Text('Sedang berjalan')),
                DropdownMenuItem(value: 'closed', child: Text('Ditutup manual')),
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
  Widget build(BuildContext context) => AppBar(title: const Text('Shift kasir'));
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift, required this.onTap});

  final ActiveShift shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          shift.status == 'open'
              ? Icons.timelapse
              : Icons.check_circle_outline,
          color: shift.status == 'open' ? Colors.orange : Colors.green,
        ),
        title: Text(shift.cashierName ?? 'Kasir'),
        subtitle: Text(
          '${_shiftStatus(shift.status)} · ${shift.outletName ?? 'Outlet'}\n'
          '${_dateTime(shift.startTime)} · Modal ${_rupiah(shift.startingCash)}'
          '\n${shift.totalTransactions} transaksi · Penjualan ${_rupiah(shift.totalSales)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
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
      appBar: AppBar(title: const Text('Detail shift')),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.cashierName ?? 'Kasir',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (shift.cashierEmail != null)
                        Text(shift.cashierEmail!),
                      const SizedBox(height: 8),
                      Text(
                        '${shift.outletName ?? 'Outlet'} · ${_shiftStatus(shift.status)}',
                      ),
                      const SizedBox(height: 12),
                      _ShiftValue(
                        label: 'Mulai',
                        value: _dateTime(shift.startTime),
                      ),
                      _ShiftValue(
                        label: 'Selesai',
                        value: shift.endTime == null
                            ? 'Belum selesai'
                            : _dateTime(shift.endTime!),
                      ),
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
                        ),
                      _ShiftValue(
                        label: 'Total penjualan',
                        value: _rupiah(shift.totalSales),
                      ),
                      _ShiftValue(
                        label: 'Jumlah transaksi',
                        value: '${shift.totalTransactions}',
                      ),
                      if (shift.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Catatan: ${shift.notes}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Transaksi (${detail.transactions.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (detail.transactions.isEmpty)
                const Card(
                  child: ListTile(title: Text('Belum ada transaksi pada shift.')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Force close gagal: $error')));
    }
  }
}

class _ShiftValue extends StatelessWidget {
  const _ShiftValue({required this.label, required this.value});

  final String label;
  final String value;

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
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
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
      child: ListTile(
        title: Text(
          '${transaction.status} · ${_rupiah(transaction.totalAmount)}',
        ),
        subtitle: Text(
          '${transaction.paymentMethod} · ${_dateTime(transaction.createdAt)}\n'
          '$details',
        ),
        isThreeLine: true,
      ),
    );
  }
}

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
            Text(
              'Kas yang diharapkan: ${_rupiah(widget.shift.expectedCash)}',
            ),
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
