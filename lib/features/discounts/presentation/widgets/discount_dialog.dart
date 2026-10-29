import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/discount_definition.dart';

class DiscountDialog extends StatefulWidget {
  const DiscountDialog({super.key, this.discount});

  final DiscountDefinition? discount;

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _descriptionController;
  late DiscountType _type;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final discount = widget.discount;
    _nameController = TextEditingController(text: discount?.name ?? '');
    _valueController = TextEditingController(
      text: discount?.value.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: discount?.description ?? '',
    );
    _type = discount?.type ?? DiscountType.percentage;
    _isActive = discount?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.discount == null ? 'Tambah Discount' : 'Edit Discount'),
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
                decoration: const InputDecoration(labelText: 'Nama discount'),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Nama minimal 2 karakter.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DiscountType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: DiscountType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Nilai',
                  suffixText: _type == DiscountType.percentage ? '%' : 'Rp',
                ),
                validator: (value) {
                  final number = num.tryParse(value ?? '');
                  if (number == null || !number.isFinite || number < 0) {
                    return 'Masukkan nilai angka nol atau lebih.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 2,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Discount aktif'),
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
      DiscountDraft(
        name: _nameController.text.trim(),
        type: _type,
        value: num.parse(_valueController.text.trim()),
        description: _descriptionController.text.trim(),
        isActive: _isActive,
      ),
    );
  }
}

class DiscountDraft {
  const DiscountDraft({
    required this.name,
    required this.type,
    required this.value,
    required this.description,
    required this.isActive,
  });

  final String name;
  final DiscountType type;
  final num value;
  final String description;
  final bool isActive;
}
