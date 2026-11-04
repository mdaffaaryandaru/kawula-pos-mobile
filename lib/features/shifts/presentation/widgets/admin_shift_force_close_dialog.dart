// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';

import 'package:kawula_pos/features/shifts/presentation/utils/admin_shift_formatters.dart'
    show formatAdminShiftRupiah;

class ForceCloseDialog extends StatefulWidget {
  const ForceCloseDialog({super.key, required this.shift});

  final ActiveShift shift;

  @override
  State<ForceCloseDialog> createState() => _ForceCloseDialogState();
}

class _ForceCloseDialogState extends State<ForceCloseDialog> {
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
              'Kas yang diharapkan: ${formatAdminShiftRupiah(widget.shift.expectedCash)}',
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
              ForceCloseDraft(
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

class ForceCloseDraft {
  const ForceCloseDraft({required this.actualCash, required this.notes});

  final num actualCash;
  final String notes;
}
