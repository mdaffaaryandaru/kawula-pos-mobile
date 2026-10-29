part of '../pages/variant_groups_management_page.dart';

// These extensions keep stateful form sections separate from the dialog shell.
// ignore_for_file: invalid_use_of_protected_member

extension _VariantGroupOptionEditors on _VariantGroupDialogState {
  Widget _optionEditor(int index) {
    final option = _options[index];
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Opsi ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (_options.length > 1)
                  IconButton(
                    tooltip: 'Hapus opsi',
                    onPressed: () => setState(() {
                      _options.removeAt(index).dispose();
                    }),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextFormField(
              controller: option.nameController,
              decoration: const InputDecoration(
                labelText: 'Nama opsi',
                hintText: 'Contoh: Large',
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Nama opsi wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: option.priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Penyesuaian harga',
                helperText: 'Gunakan nilai negatif untuk potongan harga.',
                prefixText: 'Rp ',
              ),
              validator: (value) => num.tryParse(value ?? '') == null
                  ? 'Masukkan penyesuaian harga yang valid.'
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Resep bahan (opsional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      widget.references.inventories.isEmpty ||
                          widget.references.units.isEmpty
                      ? null
                      : () => setState(
                          () => option.recipes.add(
                            _VariantRecipeForm(references: widget.references),
                          ),
                        ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            if (widget.references.inventories.isEmpty ||
                widget.references.units.isEmpty)
              Text(
                'Bahan dan satuan harus tersedia sebelum resep dapat ditambahkan.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (
              var recipeIndex = 0;
              recipeIndex < option.recipes.length;
              recipeIndex++
            )
              _recipeEditor(option, recipeIndex),
          ],
        ),
      ),
    );
  }

  Widget _recipeEditor(_VariantOptionForm option, int index) {
    final recipe = option.recipes[index];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: recipe.inventoryId,
            decoration: const InputDecoration(labelText: 'Bahan baku'),
            items: [
              for (final item in widget.references.inventories)
                DropdownMenuItem(value: item.id, child: Text(item.name)),
            ],
            validator: (value) => value == null ? 'Pilih bahan baku.' : null,
            onChanged: (value) => setState(() => recipe.inventoryId = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: recipe.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(labelText: 'Jumlah'),
                  validator: (value) {
                    final amount = num.tryParse(value ?? '');
                    return amount == null || amount < 0.001
                        ? 'Minimal 0.001.'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: recipe.unitId,
                  decoration: const InputDecoration(labelText: 'Satuan'),
                  items: [
                    for (final unit in widget.references.units)
                      DropdownMenuItem(value: unit.id, child: Text(unit.name)),
                  ],
                  validator: (value) => value == null ? 'Pilih satuan.' : null,
                  onChanged: (value) => setState(() => recipe.unitId = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: recipe.conversionFactorController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Faktor konversi',
                    helperText: 'Konversi ke satuan dasar bahan',
                  ),
                  validator: (value) {
                    final factor = num.tryParse(value ?? '');
                    return factor == null || factor < 0.0001
                        ? 'Minimal 0.0001.'
                        : null;
                  },
                ),
              ),
              IconButton(
                tooltip: 'Hapus resep',
                onPressed: () => setState(() {
                  option.recipes.removeAt(index).dispose();
                }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
