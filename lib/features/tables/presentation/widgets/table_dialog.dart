import 'package:flutter/material.dart';

import '../../../table_areas/domain/entities/table_area.dart';
import '../../data/models/managed_table_model.dart';
import '../../domain/entities/managed_table.dart';

class TableDialog extends StatefulWidget {
  const TableDialog({super.key, required this.areas, this.table});

  final List<TableArea> areas;
  final ManagedTable? table;

  @override
  State<TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends State<TableDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late String _areaId;
  late String _status;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.table?.name ?? '');
    _capacityController = TextEditingController(
      text: (widget.table?.capacity ?? 4).toString(),
    );
    _areaId =
        widget.table?.areaId ??
        (widget.areas.isEmpty ? '' : widget.areas.first.id);
    _status = widget.table?.status ?? 'available';
    _isActive = widget.table?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.table == null ? 'Tambah meja' : 'Ubah meja'),
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
                  decoration: const InputDecoration(labelText: 'Nama meja'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Nama minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _areaId.isEmpty ? null : _areaId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Area'),
                  items: widget.areas
                      .map(
                        (area) => DropdownMenuItem(
                          value: area.id,
                          child: Text(
                            area.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.areas.isEmpty
                      ? null
                      : (value) {
                          if (value != null) setState(() => _areaId = value);
                        },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Pilih area.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Kapasitas kursi',
                    suffixText: 'kursi',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final capacity = int.tryParse(value?.trim() ?? '');
                    if (capacity == null || capacity < 1) {
                      return 'Kapasitas minimal 1 kursi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status meja'),
                  items: [
                    for (final status in tableStatuses)
                      DropdownMenuItem(
                        value: status,
                        child: Text(_tableStatusLabel(status)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Meja aktif'),
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
          onPressed: widget.areas.isEmpty ? null : _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ManagedTableDraft(
        name: _nameController.text.trim(),
        areaId: _areaId,
        capacity: int.parse(_capacityController.text.trim()),
        status: _status,
        isActive: _isActive,
      ),
    );
  }

  String _tableStatusLabel(String status) => switch (status) {
    'available' => 'Tersedia',
    'occupied' => 'Terisi',
    'reserved' => 'Dipesan',
    _ => status,
  };
}

class ManagedTableDraft {
  const ManagedTableDraft({
    required this.name,
    required this.areaId,
    required this.capacity,
    required this.status,
    required this.isActive,
  });

  final String name;
  final String areaId;
  final int capacity;
  final String status;
  final bool isActive;
}
