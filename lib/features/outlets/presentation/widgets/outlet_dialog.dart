import 'package:flutter/material.dart';

import '../../domain/entities/outlet.dart';

class OutletDialog extends StatefulWidget {
  const OutletDialog({super.key, this.outlet});

  final Outlet? outlet;

  @override
  State<OutletDialog> createState() => _OutletDialogState();
}

class _OutletDialogState extends State<OutletDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.outlet?.name ?? '');
    _codeController = TextEditingController(text: widget.outlet?.code ?? '');
    _addressController = TextEditingController(
      text: widget.outlet?.address ?? '',
    );
    _phoneController = TextEditingController(text: widget.outlet?.phone ?? '');
    _isActive = widget.outlet?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.outlet == null ? 'Tambah outlet' : 'Ubah outlet'),
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
                  decoration: const InputDecoration(labelText: 'Nama outlet'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Nama minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Kode outlet'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Kode minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                  keyboardType: TextInputType.phone,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Outlet aktif'),
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
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      OutletDraft(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        isActive: _isActive,
      ),
    );
  }
}

class OutletDraft {
  const OutletDraft({
    required this.name,
    required this.code,
    required this.address,
    required this.phone,
    required this.isActive,
  });

  final String name;
  final String code;
  final String address;
  final String phone;
  final bool isActive;
}
