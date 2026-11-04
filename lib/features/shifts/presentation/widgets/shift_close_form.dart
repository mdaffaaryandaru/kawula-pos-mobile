// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_dialog_components.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_formatters.dart';

class ShiftCloseForm extends StatelessWidget {
  const ShiftCloseForm({
    super.key,
    required this.formKey,
    required this.shift,
    required this.actualCashController,
    required this.notesController,
    required this.pinController,
    required this.requiresPin,
    required this.isClosing,
    required this.onCloseShift,
    required this.onCloseDialog,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final ActiveShift shift;
  final TextEditingController actualCashController;
  final TextEditingController notesController;
  final TextEditingController pinController;
  final bool requiresPin;
  final bool isClosing;
  final VoidCallback onCloseShift;
  final VoidCallback onCloseDialog;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShiftDialogHeader(
            title: 'Tutup Shift',
            subtitle: 'Rekapitulasi penjualan shift saat ini.',
            icon: Icons.lock_outline_rounded,
            onClose: isClosing ? null : onCloseDialog,
          ),
          const SizedBox(height: 20),
          _ShiftSummaryCard(shift: shift),
          const SizedBox(height: 16),
          TextFormField(
            controller: actualCashController,
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
            controller: notesController,
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
              controller: pinController,
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
            ShiftErrorMessage(errorMessage!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: isClosing ? null : onCloseShift,
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
              child: ShiftDialogInfo(
                label: 'Kas awal',
                value: formatShiftRupiah(shift.startingCash),
              ),
            ),
            Expanded(
              child: ShiftDialogInfo(
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
          child: ShiftDialogInfo(
            label: 'Kas fisik seharusnya (total tunai + awal)',
            value: formatShiftRupiah(shift.expectedCash),
          ),
        ),
      ],
    ),
  );
}
