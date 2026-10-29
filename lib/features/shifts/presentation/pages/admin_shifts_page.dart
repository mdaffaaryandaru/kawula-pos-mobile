import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transactions/domain/entities/checkout.dart';
import '../../domain/entities/active_shift.dart';
import '../../domain/entities/admin_shift_detail.dart';
import '../../domain/repositories/admin_shifts_repository.dart';
import '../bloc/admin_shifts_cubit.dart';

part '../widgets/admin_shift_list_widgets.dart';
part '../widgets/admin_shift_detail_widgets.dart';
part '../widgets/admin_shift_force_close_dialog.dart';

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
    return AdminShiftDetailBody(
      detail: detail,
      onForceClose: () => _forceClose(detail.shift),
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
          'Kas diharapkan ${formatAdminShiftRupiah(shift.expectedCash)}.\n'
          'Kas aktual ${formatAdminShiftRupiah(draft.actualCash)}.\n'
          'Perkiraan selisih ${formatAdminShiftRupiah(draft.actualCash - shift.expectedCash)}.\n\n'
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

String adminShiftStatusLabel(String status) => switch (status) {
  'open' => 'Sedang berjalan',
  'closed' => 'Ditutup manual',
  'auto_closed' => 'Ditutup otomatis',
  _ => status,
};

String adminShiftInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList(growable: false);
  if (parts.isEmpty) return 'K';
  return parts.map((part) => part[0].toUpperCase()).join();
}

String formatAdminShiftRupiah(num amount) {
  final digits = amount.abs().toInt().toString();
  final result = StringBuffer(amount < 0 ? '-Rp ' : 'Rp ');
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  return result.toString();
}

String formatAdminShiftDateTime(DateTime? value) {
  if (value == null) return 'Waktu tidak tersedia';
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
