import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/active_shift.dart';
import '../bloc/shifts_cubit.dart';
import '../bloc/shifts_state.dart';
import 'shift_formatters.dart';

enum ShiftDialogMode { opening, closing }

Future<void> showShiftActionDialog(
  BuildContext context, {
  required AuthUser user,
  required ShiftDialogMode mode,
}) {
  final shiftsCubit = context.read<ShiftsCubit>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: shiftsCubit,
      child: _ShiftActionDialog(user: user, mode: mode),
    ),
  );
}

class _ShiftActionDialog extends StatefulWidget {
  const _ShiftActionDialog({required this.user, required this.mode});

  final AuthUser user;
  final ShiftDialogMode mode;

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
            _ShiftDialogInfo(
              label: 'Kas yang diharapkan',
              value: formatShiftRupiah(shift.expectedCash),
            ),
            _ShiftDialogInfo(
              label: 'Kas aktual',
              value: formatShiftRupiah(actualCash),
            ),
            _ShiftDialogInfo(
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
  }) {
    final canOpen =
        widget.user.hasPin && availability.availableCash >= 0 && !isOpening;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DialogHeader(
            title: 'Buka Shift Kasir',
            subtitle: 'Masukkan modal awal laci dan PIN Anda.',
            icon: Icons.lock_open_rounded,
            onClose: isOpening ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 20),
          _AvailabilityCard(availability: availability),
          const SizedBox(height: 16),
          if (!widget.user.hasPin)
            const Text(
              'PIN belum diatur. Hubungi admin untuk mengatur PIN sebelum membuka shift.',
            )
          else ...[
            TextFormField(
              controller: _startingCashController,
              enabled: !isOpening,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              decoration: const InputDecoration(
                labelText: 'Modal awal (Rp)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = num.tryParse(value?.trim() ?? '');
                if (amount == null || amount < 0) {
                  return 'Masukkan nominal yang valid.';
                }
                if (amount > availability.availableCash) {
                  return 'Modal melebihi kas yang tersedia.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openPinController,
              enabled: !isOpening,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'PIN (4 digit)',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || !RegExp(r'^\d{4}$').hasMatch(value)) {
                  return 'PIN harus terdiri dari 4 angka.';
                }
                return null;
              },
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(errorMessage),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canOpen ? _openShift : null,
            child: isOpening
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mulai Shift'),
          ),
        ],
      ),
    );
  }

  Widget _closingForm(
    ActiveShift shift, {
    String? errorMessage,
    bool isClosing = false,
  }) {
    final requiresPin = widget.user.role != 'Admin';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DialogHeader(
            title: 'Tutup Shift',
            subtitle: 'Rekapitulasi penjualan shift saat ini.',
            icon: Icons.lock_outline_rounded,
            onClose: isClosing ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 20),
          _ShiftSummaryCard(shift: shift),
          const SizedBox(height: 16),
          TextFormField(
            controller: _actualCashController,
            enabled: !isClosing,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: const InputDecoration(
              labelText: 'Hitung kas fisik laci (Rp)',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final amount = num.tryParse(value?.trim() ?? '');
              if (amount == null || amount < 0) {
                return 'Masukkan kas aktual yang valid.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            enabled: !isClosing,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan / alasan selisih (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (requiresPin) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _closePinController,
              enabled: !isClosing,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Otorisasi PIN (4 digit)',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || !RegExp(r'^\d{4}$').hasMatch(value)) {
                  return 'PIN harus terdiri dari 4 angka.';
                }
                return null;
              },
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(errorMessage),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: isClosing ? null : () => _closeShift(shift),
            child: isClosing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tutup Shift Sekarang'),
          ),
        ],
      ),
    );
  }

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
          _ShiftDialogInfo(
            label: 'Selesai',
            value: formatShiftDateTime(endTime),
          ),
        _ShiftDialogInfo(
          label: 'Kas yang diharapkan',
          value: formatShiftRupiah(shift.expectedCash),
        ),
        if (shift.actualCash case final actualCash?)
          _ShiftDialogInfo(
            label: 'Kas aktual',
            value: formatShiftRupiah(actualCash),
          ),
        if (shift.cashDifference case final difference?)
          _ShiftDialogInfo(
            label: 'Selisih kas',
            value: formatShiftRupiah(difference),
          ),
        _ShiftDialogInfo(
          label: 'Total penjualan',
          value: formatShiftRupiah(shift.totalSales),
        ),
        _ShiftDialogInfo(
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
        _DialogHeader(
          title: 'Status shift belum tersedia',
          icon: Icons.cloud_off_outlined,
          onClose: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 16),
        _ErrorMessage(message),
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

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.icon,
    required this.onClose,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ],
        ),
      ),
      IconButton(
        onPressed: onClose,
        tooltip: 'Tutup dialog',
        icon: const Icon(Icons.close),
        visualDensity: VisualDensity.compact,
      ),
    ],
  );
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.availability});

  final CashAvailability availability;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kas tersedia'),
        const SizedBox(height: 4),
        Text(
          formatShiftRupiah(availability.availableCash),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ShiftSummaryCard extends StatelessWidget {
  const _ShiftSummaryCard({required this.shift});

  final ActiveShift shift;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ShiftDialogInfo(
                label: 'Kas awal',
                value: formatShiftRupiah(shift.startingCash),
              ),
            ),
            Expanded(
              child: _ShiftDialogInfo(
                label: 'Total penjualan',
                value: formatShiftRupiah(shift.totalSales),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _ShiftDialogInfo(
            label: 'Kas fisik seharusnya (total tunai + awal)',
            value: formatShiftRupiah(shift.expectedCash),
          ),
        ),
      ],
    ),
  );
}

class _ShiftDialogInfo extends StatelessWidget {
  const _ShiftDialogInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).hintColor),
      ),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
    ),
  );
}
