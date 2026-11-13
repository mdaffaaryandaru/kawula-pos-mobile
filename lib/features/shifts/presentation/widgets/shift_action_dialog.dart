// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/offline/domain/policies/offline_sales_policy.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_state.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_close_form.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_dialog_components.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_formatters.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_open_form.dart';

enum ShiftDialogMode { opening, closing }

Future<void> showShiftActionDialog(
  BuildContext context, {
  required AuthUser user,
  required ShiftDialogMode mode,
  Future<int> Function(ActiveShift shift)?
  loadUnresolvedOfflineTransactionCount,
  VoidCallback? onOpenOfflineQueue,
}) {
  final shiftsCubit = context.read<ShiftsCubit>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: shiftsCubit,
      child: _ShiftActionDialog(
        user: user,
        mode: mode,
        loadUnresolvedOfflineTransactionCount:
            loadUnresolvedOfflineTransactionCount,
        onOpenOfflineQueue: onOpenOfflineQueue,
      ),
    ),
  );
}

class _ShiftActionDialog extends StatefulWidget {
  const _ShiftActionDialog({
    required this.user,
    required this.mode,
    this.loadUnresolvedOfflineTransactionCount,
    this.onOpenOfflineQueue,
  });

  final AuthUser user;
  final ShiftDialogMode mode;
  final Future<int> Function(ActiveShift shift)?
  loadUnresolvedOfflineTransactionCount;
  final VoidCallback? onOpenOfflineQueue;

  @override
  State<_ShiftActionDialog> createState() => _ShiftActionDialogState();
}

class _ShiftActionDialogState extends State<_ShiftActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startingCashController = TextEditingController();
  final _openPinController = TextEditingController();
  final _actualCashController = TextEditingController();
  final _closePinController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _startingCashController.dispose();
    _openPinController.dispose();
    _actualCashController.dispose();
    _closePinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openShift() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<ShiftsCubit>().openShift(
      startingCash: num.parse(_startingCashController.text.trim()),
      pin: _openPinController.text,
    );
    if (!mounted) return;
    if (context.read<ShiftsCubit>().state is ShiftsActive) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _closeShift(ActiveShift shift) async {
    if (!_formKey.currentState!.validate()) return;

    if (canUseOfflineSales(widget.user.role) &&
        widget.loadUnresolvedOfflineTransactionCount != null) {
      try {
        final unresolvedCount =
            await widget.loadUnresolvedOfflineTransactionCount!(shift);
        if (!mounted) return;
        if (unresolvedCount > 0) {
          final openQueue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Shift belum dapat ditutup'),
              content: Text(
                'Ada $unresolvedCount transaksi offline pada kasir, outlet, '
                'dan shift ini yang belum terselesaikan. Status pending_sync, '
                'syncing, failed, dan needs_reconciliation semuanya '
                'memblokir tutup shift. Transaksi gagal atau yang perlu '
                'pencocokan harus ditindaklanjuti bersama manajemen; '
                'jangan hapus transaksi untuk melewati pemeriksaan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Kembali'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Lihat antrean'),
                ),
              ],
            ),
          );
          if (openQueue == true && mounted) {
            Navigator.of(context).pop();
            widget.onOpenOfflineQueue?.call();
          }
          return;
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Antrean offline tidak dapat diperiksa. Shift tidak ditutup: $error',
            ),
          ),
        );
        return;
      }
    }

    final actualCash = num.parse(_actualCashController.text.trim());
    final difference = actualCash - shift.expectedCash;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi tutup shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shift akan ditutup dan tidak dapat dibuka kembali.'),
            const SizedBox(height: 16),
            ShiftDialogInfo(
              label: 'Kas yang diharapkan',
              value: formatShiftRupiah(shift.expectedCash),
            ),
            ShiftDialogInfo(
              label: 'Kas aktual',
              value: formatShiftRupiah(actualCash),
            ),
            ShiftDialogInfo(
              label: 'Perkiraan selisih',
              value: formatShiftRupiah(difference),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, tutup shift'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<ShiftsCubit>().closeShift(
      actualCash: actualCash,
      pin: widget.user.role == 'Admin' ? null : _closePinController.text,
      notes: _notesController.text,
    );
  }

  Future<void> _retry() async {
    final cubit = context.read<ShiftsCubit>();
    await cubit.loadActive();
    if (!mounted) return;

    final state = cubit.state;
    final canDismiss = switch (widget.mode) {
      ShiftDialogMode.opening => state is ShiftsActive,
      ShiftDialogMode.closing =>
        state is ShiftsNeedsOpening || state is ShiftsClosed,
    };
    if (canDismiss) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return BlocBuilder<ShiftsCubit, ShiftsState>(
      builder: (context, state) {
        final isOpening = state is ShiftsOpening;
        final isClosing = state is ShiftsClosing;
        final isBusy = isOpening || isClosing;

        if (widget.mode == ShiftDialogMode.closing &&
            state is ShiftsActive &&
            _actualCashController.text.isEmpty) {
          _actualCashController.text = state.shift.expectedCash
              .round()
              .toString();
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: SizedBox(
            width: screenWidth < 472 ? screenWidth - 48 : 440,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: switch ((widget.mode, state)) {
                (
                  ShiftDialogMode.opening,
                  ShiftsNeedsOpening(
                    cashAvailability: final availability,
                    errorMessage: final errorMessage,
                  ),
                ) =>
                  _openingForm(
                    availability,
                    errorMessage: errorMessage,
                    isOpening: false,
                  ),
                (
                  ShiftDialogMode.opening,
                  ShiftsOpening(cashAvailability: final availability),
                ) =>
                  _openingForm(availability, isOpening: true),
                (
                  ShiftDialogMode.closing,
                  ShiftsActive(
                    shift: final shift,
                    errorMessage: final errorMessage,
                  ),
                ) =>
                  _closingForm(shift, errorMessage: errorMessage),
                (ShiftDialogMode.closing, ShiftsClosing(shift: final shift)) =>
                  _closingForm(shift, isClosing: true),
                (ShiftDialogMode.closing, ShiftsClosed(shift: final shift)) =>
                  _closedSummary(shift),
                (_, ShiftsFailure(message: final message)) => _failure(message),
                _ => _waiting(isBusy),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _openingForm(
    CashAvailability availability, {
    String? errorMessage,
    required bool isOpening,
  }) => ShiftOpenForm(
    formKey: _formKey,
    user: widget.user,
    startingCashController: _startingCashController,
    pinController: _openPinController,
    availability: availability,
    isOpening: isOpening,
    onOpen: _openShift,
    onClose: () => Navigator.of(context).pop(),
    errorMessage: errorMessage,
  );

  Widget _closingForm(
    ActiveShift shift, {
    String? errorMessage,
    bool isClosing = false,
  }) => ShiftCloseForm(
    formKey: _formKey,
    shift: shift,
    actualCashController: _actualCashController,
    notesController: _notesController,
    pinController: _closePinController,
    requiresPin: widget.user.role != 'Admin',
    isClosing: isClosing,
    onCloseShift: () => _closeShift(shift),
    onCloseDialog: () => Navigator.of(context).pop(),
    errorMessage: errorMessage,
  );

  Widget _closedSummary(ActiveShift shift) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.task_alt, size: 48, color: Colors.green),
        const SizedBox(height: 12),
        Text(
          'Shift berhasil ditutup',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Divider(height: 32),
        if (shift.endTime case final endTime?)
          ShiftDialogInfo(
            label: 'Selesai',
            value: formatShiftDateTime(endTime),
          ),
        ShiftDialogInfo(
          label: 'Kas yang diharapkan',
          value: formatShiftRupiah(shift.expectedCash),
        ),
        if (shift.actualCash case final actualCash?)
          ShiftDialogInfo(
            label: 'Kas aktual',
            value: formatShiftRupiah(actualCash),
          ),
        if (shift.cashDifference case final difference?)
          ShiftDialogInfo(
            label: 'Selisih kas',
            value: formatShiftRupiah(difference),
          ),
        ShiftDialogInfo(
          label: 'Total penjualan',
          value: formatShiftRupiah(shift.totalSales),
        ),
        ShiftDialogInfo(
          label: 'Jumlah transaksi',
          value: '${shift.totalTransactions}',
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<ShiftsCubit>().loadActive();
          },
          child: const Text('Selesai'),
        ),
      ],
    );
  }

  Widget _failure(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShiftDialogHeader(
          title: 'Status shift belum tersedia',
          icon: Icons.cloud_off_outlined,
          onClose: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 16),
        ShiftErrorMessage(message),
        const SizedBox(height: 16),
        FilledButton(onPressed: _retry, child: const Text('Coba lagi')),
      ],
    );
  }

  Widget _waiting(bool isBusy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(isBusy ? 'Memproses shift...' : 'Memuat status shift...'),
        ],
      ),
    );
  }
}
