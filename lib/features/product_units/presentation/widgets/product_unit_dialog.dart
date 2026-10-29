import 'package:flutter/material.dart';

import '../../domain/entities/product_unit.dart';

class ProductUnitDialog extends StatefulWidget {
  const ProductUnitDialog({super.key, this.unit});

  final ProductUnit? unit;

  @override
  State<ProductUnitDialog> createState() => _ProductUnitDialogState();
}

class _ProductUnitDialogState extends State<ProductUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _abbreviationController;
  late final TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _abbreviationController = TextEditingController(
      text: widget.unit?.abbreviation ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.unit?.description ?? '',
    );
    _isActive = widget.unit?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbreviationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.unit != null;
    final maxHeight = MediaQuery.sizeOf(context).height * .85;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                editing ? 'Edit Product Unit' : 'Tambah Product Unit',
              ),
              subtitle: Text(
                editing
                    ? 'Ubah informasi satuan produk.'
                    : 'Tambahkan satuan untuk inventaris dan POS.',
              ),
              trailing: IconButton(
                tooltip: 'Tutup',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama satuan',
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Nama minimal 2 karakter.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _abbreviationController,
                      textCapitalization: TextCapitalization.none,
                      decoration: const InputDecoration(
                        labelText: 'Singkatan',
                        hintText: 'Contoh: kg, pcs, ml',
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Singkatan wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi (opsional)',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Satuan aktif'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(editing ? 'Simpan Perubahan' : 'Tambah Unit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ProductUnitDraft(
        name: _nameController.text.trim(),
        abbreviation: _abbreviationController.text.trim(),
        description: _descriptionController.text.trim(),
        isActive: _isActive,
      ),
    );
  }
}

class ProductUnitDraft {
  const ProductUnitDraft({
    required this.name,
    required this.abbreviation,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String abbreviation;
  final String description;
  final bool isActive;
}
