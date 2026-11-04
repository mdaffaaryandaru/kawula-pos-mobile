// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/entities/admin_shift_detail.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/admin_shifts_repository.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/admin_shifts_cubit.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/admin_shift_detail_widgets.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/admin_shift_force_close_dialog.dart';
import 'package:kawula_pos/features/shifts/presentation/utils/admin_shift_formatters.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/admin_shift_history_controls.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/admin_shift_history_views.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class AdminShiftsPage extends StatefulWidget {
  const AdminShiftsPage({super.key, required this.repository});

  final AdminShiftsRepository repository;

  @override
  State<AdminShiftsPage> createState() => _AdminShiftsPageState();
}

class _AdminShiftsPageState extends State<AdminShiftsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminShiftsCubit(widget.repository)..load(),
      child: BlocBuilder<AdminShiftsCubit, AdminShiftsState>(
        builder: (context, state) => switch (state) {
          AdminShiftsLoading() => const Scaffold(
            appBar: AdminShiftsAppBar(),
            body: Center(child: CircularProgressIndicator()),
          ),
          AdminShiftsFailure() => Scaffold(
            appBar: const AdminShiftsAppBar(),
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
    final shifts = state.shifts.where(_matchesSearch).toList(growable: false);
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(title: const ShiftLogoTitle(title: 'Shift kasir')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 900 ? 28.0 : 16.0;
          final contentWidth = constraints.maxWidth >= 1500
              ? 1440.0
              : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: contentWidth,
              child: RefreshIndicator(
                onRefresh: () => context.read<AdminShiftsCubit>().load(
                  status: state.statusFilter,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    32,
                  ),
                  children: [
                    ShiftHistoryHeader(
                      onRefresh: () => context.read<AdminShiftsCubit>().load(
                        status: state.statusFilter,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShiftHistorySearch(
                      controller: _searchController,
                      onChanged: (value) => setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      }),
                      selectedStatus: state.statusFilter,
                      onStatusChanged: (value) =>
                          context.read<AdminShiftsCubit>().load(
                            status: value == null || value == 'all'
                                ? null
                                : value,
                          ),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      MaterialBanner(
                        content: Text(state.errorMessage!),
                        actions: [
                          TextButton(
                            onPressed: () => context
                                .read<AdminShiftsCubit>()
                                .load(status: state.statusFilter),
                            child: const Text('Muat ulang'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (shifts.isEmpty)
                      const ShiftHistoryEmpty()
                    else
                      LayoutBuilder(
                        builder: (context, tableConstraints) {
                          if (tableConstraints.maxWidth < 760) {
                            return Column(
                              children: shifts
                                  .map(
                                    (shift) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: ShiftCard(
                                        shift: shift,
                                        onTap: () => _openDetails(
                                          context,
                                          shift,
                                          state.statusFilter,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            );
                          }
                          return ShiftHistoryTable(
                            shifts: shifts,
                            minWidth: tableConstraints.maxWidth,
                            onDetails: (shift) => _openDetails(
                              context,
                              shift,
                              state.statusFilter,
                            ),
                            onForceClose: (shift) async {
                              final closed = await forceCloseAdminShift(
                                context,
                                widget.repository,
                                shift,
                              );
                              if (context.mounted && closed) {
                                await context.read<AdminShiftsCubit>().load(
                                  status: state.statusFilter,
                                );
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _matchesSearch(ActiveShift shift) {
    if (_searchQuery.isEmpty) return true;
    return [
      shift.cashierName,
      shift.cashierEmail,
      shift.outletName,
      adminShiftStatusLabel(shift.status),
      shift.status,
    ].whereType<String>().any(
      (value) => value.toLowerCase().contains(_searchQuery),
    );
  }

  Future<void> _openDetails(
    BuildContext context,
    ActiveShift shift,
    String? statusFilter,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminShiftDetailPage(
          shiftId: shift.id,
          repository: widget.repository,
        ),
      ),
    );
    if (context.mounted && changed == true) {
      await context.read<AdminShiftsCubit>().load(status: statusFilter);
    }
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
      appBar: AppBar(title: const ShiftLogoTitle(title: 'Detail shift')),
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
    final closed = await forceCloseAdminShift(
      context,
      widget.repository,
      shift,
    );
    if (closed && mounted) Navigator.pop(context, true);
  }
}

Future<bool> forceCloseAdminShift(
  BuildContext context,
  AdminShiftsRepository repository,
  ActiveShift shift,
) async {
  final draft = await showDialog<ForceCloseDraft>(
    context: context,
    builder: (_) => ForceCloseDialog(shift: shift),
  );
  if (draft == null || !context.mounted) return false;
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
  if (confirmed != true || !context.mounted) return false;
  try {
    await repository.forceCloseShift(
      shiftId: shift.id,
      actualCash: draft.actualCash,
      notes: draft.notes,
    );
    return true;
  } catch (error) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Force close gagal: $error')));
    return false;
  }
}

String adminShiftStatusLabel(String status) => switch (status) {
  'open' => 'Sedang berjalan',
  'closed' => 'Ditutup manual',
  'auto_closed' => 'Ditutup otomatis',
  _ => status,
};
