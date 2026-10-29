import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/active_shift.dart';
import '../bloc/shifts_cubit.dart';
import '../widgets/active_shift_view.dart';
import '../widgets/closed_shift_view.dart';
import '../widgets/opening_shift_view.dart';
import '../widgets/shift_formatters.dart';
import '../widgets/shift_status_widgets.dart';

class ShiftStatusView extends StatefulWidget {
  const ShiftStatusView({
    super.key,
    required this.user,
    this.shift,
    this.cashAvailability,
    this.errorMessage,
    this.isOpening = false,
    this.isClosing = false,
    this.isClosed = false,
  });

  final AuthUser user;
  final ActiveShift? shift;
  final CashAvailability? cashAvailability;
  final String? errorMessage;
  final bool isOpening;
  final bool isClosing;
  final bool isClosed;

  @override
  State<ShiftStatusView> createState() => _ShiftStatusViewState();
}

class _ShiftStatusViewState extends State<ShiftStatusView> {
  final _formKey = GlobalKey<FormState>();
  final _closeFormKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _pinController = TextEditingController();
  final _actualCashController = TextEditingController();
  final _closePinController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isCloseFormVisible = false;

  @override
  void initState() {
    super.initState();
    final shift = widget.shift;
    if (shift != null) {
      _actualCashController.text = shift.expectedCash.round().toString();
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _pinController.dispose();
    _actualCashController.dispose();
    _closePinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openShift() async {
    if (!_formKey.currentState!.validate()) return;
    final cash = num.parse(_cashController.text.trim());
    await context.read<ShiftsCubit>().openShift(
      startingCash: cash,
      pin: _pinController.text,
    );
  }

  Future<void> _confirmCloseShift(ActiveShift shift, bool requiresPin) async {
    if (!_closeFormKey.currentState!.validate()) return;

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
            ShiftInfoRow(
              label: 'Kas yang diharapkan',
              value: formatShiftRupiah(shift.expectedCash),
            ),
            ShiftInfoRow(
              label: 'Kas aktual',
              value: formatShiftRupiah(actualCash),
            ),
            ShiftInfoRow(
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
      pin: requiresPin ? _closePinController.text : null,
      notes: _notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    if (shift != null) {
      if (widget.isClosed) {
        return ClosedShiftView(
          shift: shift,
          onDone: context.read<ShiftsCubit>().loadActive,
        );
      }
      return ActiveShiftView(
        user: widget.user,
        shift: shift,
        errorMessage: widget.errorMessage,
        isClosing: widget.isClosing,
        isCloseFormVisible: _isCloseFormVisible,
        closeFormKey: _closeFormKey,
        actualCashController: _actualCashController,
        closePinController: _closePinController,
        notesController: _notesController,
        onShowCloseForm: () => setState(() => _isCloseFormVisible = true),
        onHideCloseForm: () => setState(() => _isCloseFormVisible = false),
        onConfirmClose: (requiresPin) => _confirmCloseShift(shift, requiresPin),
        onRefresh: context.read<ShiftsCubit>().loadActive,
      );
    }
    return OpeningShiftView(
      user: widget.user,
      cashAvailability: widget.cashAvailability,
      errorMessage: widget.errorMessage,
      isOpening: widget.isOpening,
      formKey: _formKey,
      cashController: _cashController,
      pinController: _pinController,
      onOpen: _openShift,
      onRefresh: context.read<ShiftsCubit>().loadActive,
    );
  }
}
