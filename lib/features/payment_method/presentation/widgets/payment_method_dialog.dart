import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/payment_method.dart';

class PaymentMethodDialog extends StatefulWidget {
  const PaymentMethodDialog({super.key, this.paymentMethod});

  final PaymentMethod? paymentMethod;

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final paymentMethod = widget.paymentMethod;
    _nameController = TextEditingController(text: paymentMethod?.name ?? '');
    _codeController = TextEditingController(text: paymentMethod?.code ?? '');
    _descriptionController = TextEditingController(
      text: paymentMethod?.description ?? '',
    );
    _isActive = paymentMethod?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.paymentMethod == null
          ? 'Tambah Metode Pembayaran'
          : 'Edit Metode Pembayaran',
    ),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Nama minimal 2 karakter.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                enabled: widget.paymentMethod == null,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_UpperCaseTextFormatter()],
                decoration: InputDecoration(
                  labelText: 'Kode',
                  helperText: widget.paymentMethod == null
                      ? 'Kode digunakan pada transaksi dan tidak dapat diubah.'
                      : 'Kode tidak dapat diubah.',
                ),
                validator: (value) =>
                    widget.paymentMethod == null &&
                        (value?.trim().length ?? 0) < 2
                    ? 'Kode minimal 2 karakter.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 2,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Metode aktif'),
                subtitle: const Text(
                  'Metode aktif dapat dipilih saat pembayaran di kasir.',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Simpan')),
    ],
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      PaymentMethodDraft(
        name: _nameController.text.trim(),
        code: widget.paymentMethod == null
            ? _codeController.text.trim().toUpperCase()
            : null,
        description: _descriptionController.text.trim(),
        isActive: _isActive,
      ),
    );
  }
}

class PaymentMethodDraft {
  const PaymentMethodDraft({
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String? code;
  final String description;
  final bool isActive;
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}
