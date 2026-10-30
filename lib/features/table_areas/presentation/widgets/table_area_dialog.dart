import 'package:flutter/material.dart';

import '../../../outlets/domain/entities/outlet.dart';
import '../../domain/entities/table_area.dart';

class TableAreaDialog extends StatefulWidget {
  const TableAreaDialog({super.key, required this.outlets, this.area});

  final List<Outlet> outlets;
  final TableArea? area;

  @override
  State<TableAreaDialog> createState() => _TableAreaDialogState();
}

class _TableAreaDialogState extends State<TableAreaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _outletId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.area?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.area?.description ?? '',
    );
    _outletId =
        widget.area?.outletId ??
        (widget.outlets.isEmpty ? '' : widget.outlets.first.id);
    _isActive = widget.area?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.area == null ? 'Tambah area' : 'Ubah area'),
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
                  decoration: const InputDecoration(labelText: 'Nama area'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Nama minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _outletId.isEmpty ? null : _outletId,
                  decoration: const InputDecoration(labelText: 'Outlet'),
                  items: widget.outlets
                      .map(
                        (outlet) => DropdownMenuItem(
                          value: outlet.id,
                          child: Text(
                            outlet.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.outlets.isEmpty
                      ? null
                      : (value) {
                          if (value != null) setState(() => _outletId = value);
                        },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Pilih outlet.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 2,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Area aktif'),
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
        FilledButton(
          onPressed: widget.outlets.isEmpty ? null : _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TableAreaDraft(
        name: _nameController.text.trim(),
        outletId: _outletId,
        description: _descriptionController.text.trim(),
        isActive: _isActive,
      ),
    );
  }
}

class TableAreaDraft {
  const TableAreaDraft({
    required this.name,
    required this.outletId,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String outletId;
  final String description;
  final bool isActive;
}
