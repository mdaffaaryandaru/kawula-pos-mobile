import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/inventory_item.dart';
import '../../../product_units/domain/entities/product_unit.dart';

class InventoryFormDialog extends StatefulWidget {
  const InventoryFormDialog({super.key, required this.units, this.item});

  final List<ProductUnit> units;
  final InventoryItem? item;

  @override
  State<InventoryFormDialog> createState() => _InventoryFormDialogState();
}

class _InventoryFormDialogState extends State<InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _stock;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _buyPrice;
  late final TextEditingController _minStock;
  late final TextEditingController _maxStock;
  late String? _unitId;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _stock = TextEditingController(text: item?.stock.toString() ?? '0');
    _category = TextEditingController(text: item?.category ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _buyPrice = TextEditingController(text: item?.buyPrice.toString() ?? '0');
    _minStock = TextEditingController(text: item?.minStock.toString() ?? '0');
    _maxStock = TextEditingController(text: item?.maxStock?.toString() ?? '');
    _unitId = widget.units.any((unit) => unit.id == item?.unit.id)
        ? item!.unit.id
        : widget.units.firstOrNull?.id;
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _stock.dispose();
    _category.dispose();
    _description.dispose();
    _buyPrice.dispose();
    _minStock.dispose();
    _maxStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    final dimensions = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: dimensions.height * .9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(editing ? 'Ubah bahan' : 'Tambah bahan'),
              subtitle: const Text('Lengkapi informasi dan satuan stok.'),
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
                  padding: const EdgeInsets.all(20),
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama bahan *',
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? 'Nama minimal 2 karakter.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _unitId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Satuan *'),
                      items: widget.units
                          .where((unit) => unit.isActive || unit.id == _unitId)
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit.id,
                              child: Text(unit.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _unitId = value),
                      validator: (value) =>
                          value == null ? 'Pilih satuan.' : null,
                    ),
                    const SizedBox(height: 12),
                    _numberField(
                      _stock,
                      label: editing ? 'Stok saat ini' : 'Stok awal',
                      enabled: !editing,
                    ),
                    const SizedBox(height: 12),
                    _numberField(_buyPrice, label: 'Harga beli'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _numberField(_minStock, label: 'Stok minimum'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _numberField(
                            _maxStock,
                            label: 'Stok maksimum (opsional)',
                            optional: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 2,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bahan aktif'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
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
                    child: Text(editing ? 'Simpan perubahan' : 'Tambah bahan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller, {
    required String label,
    bool optional = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final raw = value?.trim() ?? '';
        if (optional && raw.isEmpty) return null;
        final parsed = num.tryParse(raw);
        if (parsed == null || parsed < 0) return 'Masukkan angka 0 atau lebih.';
        return null;
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      InventoryDraft(
        name: _name.text.trim(),
        stock: num.parse(_stock.text.trim()),
        unitId: _unitId!,
        category: _category.text.trim(),
        description: _description.text.trim(),
        buyPrice: num.parse(_buyPrice.text.trim()),
        minStock: num.parse(_minStock.text.trim()),
        maxStock: _maxStock.text.trim().isEmpty
            ? null
            : num.parse(_maxStock.text.trim()),
        isActive: _isActive,
      ),
    );
  }
}

class InventoryDraft {
  const InventoryDraft({
    required this.name,
    required this.stock,
    required this.unitId,
    required this.category,
    required this.description,
    required this.buyPrice,
    required this.minStock,
    required this.maxStock,
    required this.isActive,
  });

  final String name;
  final num stock;
  final String unitId;
  final String category;
  final String description;
  final num buyPrice;
  final num minStock;
  final num? maxStock;
  final bool isActive;
}

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({super.key, required this.item});

  final InventoryItem item;

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _notes = TextEditingController();
  String _type = 'in';

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Penyesuaian stok'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Stok saat ini: ${_quantityLabel(widget.item.stock)} ${widget.item.unit.abbreviation}',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Jenis penyesuaian'),
            items: const [
              DropdownMenuItem(value: 'in', child: Text('Stok masuk')),
              DropdownMenuItem(value: 'out', child: Text('Stok keluar')),
            ],
            onChanged: (value) => setState(() => _type = value ?? 'in'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Jumlah (${widget.item.unit.abbreviation})',
            ),
            validator: (value) {
              final amount = num.tryParse(value?.trim() ?? '');
              return amount == null || amount < .001
                  ? 'Jumlah minimal 0,001.'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            maxLines: 2,
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
            StockAdjustmentDraft(
              type: _type,
              quantity: num.parse(_quantity.text.trim()),
              notes: _notes.text.trim(),
            ),
          );
        },
        child: const Text('Simpan'),
      ),
    ],
  );
}

class StockAdjustmentDraft {
  const StockAdjustmentDraft({
    required this.type,
    required this.quantity,
    required this.notes,
  });

  final String type;
  final num quantity;
  final String notes;
}

String _quantityLabel(num value) =>
    value == value.toInt() ? value.toInt().toString() : value.toString();
