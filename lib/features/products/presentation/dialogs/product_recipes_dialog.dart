import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';
import '../../../inventories/domain/entities/inventory_item.dart';
import '../../../products/domain/entities/product_management.dart';
import '../widgets/product_management_helpers.dart';

typedef RecipeAdder = Future<bool> Function({
  required String inventoryId,
  required num quantity,
  required String unitId,
  required num conversionFactor,
});

typedef RecipeRemover = Future<bool> Function(int recipeIndex);

class ProductRecipesDialog extends StatefulWidget {
  const ProductRecipesDialog({
    super.key,
    required this.item,
    required this.inventories,
    required this.productUnits,
    required this.onAdd,
    required this.onRemove,
  });

  final ManagedProduct item;
  final List<InventoryItem> inventories;
  final List<ProductUnit> productUnits;
  final RecipeAdder onAdd;
  final RecipeRemover onRemove;

  @override
  State<ProductRecipesDialog> createState() => _ProductRecipesDialogState();
}

class _ProductRecipesDialogState extends State<ProductRecipesDialog> {
  late final TextEditingController _quantityController;
  late List<ProductRecipe> _recipes;
  String? _inventoryId;
  String? _unitId;
  var _busy = false;
  String? _errorMessage;

  List<InventoryItem> get _activeInventories =>
      widget.inventories.where((inventory) => inventory.isActive).toList();

  num get _estimatedRecipeCost => _recipes.fold<num>(0, (total, recipe) {
    final inventory = widget.inventories
        .where((item) => item.id == recipe.inventoryId)
        .firstOrNull;
    if (inventory == null) return total;
    return total +
        recipe.quantity * recipe.conversionFactor * inventory.buyPrice;
  });

  bool get _hasUnpricedRecipes => _recipes.any(
    (recipe) => !widget.inventories.any(
      (inventory) => inventory.id == recipe.inventoryId,
    ),
  );

  InventoryItem? get _selectedInventory => widget.inventories
      .where((inventory) => inventory.id == _inventoryId)
      .firstOrNull;

  List<ProductUnit> get _availableUnits {
    final inventory = _selectedInventory;
    if (inventory == null) return const [];
    final units = <ProductUnit>[inventory.unit];
    for (final unit in widget.productUnits) {
      if (unit.isActive &&
          _conversionFactor(inventory.unit, unit) != null &&
          !units.any((existing) => existing.id == unit.id)) {
        units.add(unit);
      }
    }
    return units;
  }

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _recipes = [...widget.item.recipes];
    final firstInventory = _activeInventories.firstOrNull;
    _inventoryId = firstInventory?.id;
    _unitId = firstInventory?.unit.id;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = _selectedInventory;
    final units = _availableUnits;
    if (!units.any((unit) => unit.id == _unitId)) {
      _unitId = units.firstOrNull?.id;
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recipe: ${widget.item.product.name}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Atur bahan baku dan satuan pemakaian untuk satu produk.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup resep',
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _recipeCostEstimate(),
              const SizedBox(height: 12),
              if (_activeInventories.isEmpty)
                _RecipeMessage(
                  message: widget.productUnits.isEmpty
                      ? 'Data bahan dan satuan tidak tersedia. Periksa koneksi '
                            'lalu refresh halaman produk.'
                      : 'Belum ada bahan aktif di Inventories.',
                )
              else if (widget.productUnits.isEmpty)
                const _RecipeMessage(
                  message: 'Data satuan tidak tersedia. Refresh daftar produk.',
                )
              else
                _recipeEntry(inventory, units),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dashboardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total bahan ${_recipes.length} item',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Stok dihitung saat transaksi lunas',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _recipes.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada bahan untuk produk ini.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _recipes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          return Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8FBF3),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.science_outlined,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.inventoryName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${recipe.quantityLabel} per produk',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus bahan',
                                  onPressed: _busy
                                      ? null
                                      : () => _removeRecipe(index),
                                  color: AppColors.danger,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recipeCostEstimate() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      border: Border.all(color: const Color(0xFFA7F3D0)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.calculate_outlined, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimasi HPP / produk',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _hasUnpricedRecipes
                    ? '${formatProductRupiah(_estimatedRecipeCost)} (belum lengkap)'
                    : formatProductRupiah(_estimatedRecipeCost),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Berdasarkan harga modal inventori dan resep saat ini. Bahan dari opsi varian belum termasuk.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _recipeEntry(InventoryItem? inventory, List<ProductUnit> units) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dashboardBackground,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 620) {
                return Row(
                  children: [
                    Expanded(flex: 2, child: _inventoryField()),
                    const SizedBox(width: 10),
                    Expanded(child: _quantityField()),
                    const SizedBox(width: 10),
                    Expanded(child: _unitField(units)),
                  ],
                );
              }
              return Column(
                children: [
                  _inventoryField(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(width: 120, child: _quantityField()),
                      const SizedBox(width: 10),
                      Expanded(child: _unitField(units)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  inventory == null
                      ? 'Pilih bahan untuk melihat satuan stok.'
                      : 'Konversi otomatis ke satuan stok: '
                            '${inventory.unit.label}.',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _busy || inventory == null || _unitId == null
                    ? null
                    : _addRecipe,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Tambah Bahan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inventoryField() => DropdownButtonFormField<String>(
    initialValue: _inventoryId,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Bahan Inventory',
      filled: true,
      fillColor: AppColors.surface,
    ),
    items: _activeInventories
        .map(
          (item) => DropdownMenuItem(
            value: item.id,
            child: Text(
              '${item.name} (${formatProductNumber(item.stock)} '
              '${item.unit.abbreviation})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: _busy
        ? null
        : (value) {
            final item = _activeInventories
                .where((inventory) => inventory.id == value)
                .firstOrNull;
            setState(() {
              _inventoryId = value;
              _unitId = item?.unit.id;
            });
          },
  );

  Widget _quantityField() => TextField(
    controller: _quantityController,
    enabled: !_busy,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    decoration: const InputDecoration(
      labelText: 'Jumlah Recipe',
      hintText: 'Mis. 15',
      filled: true,
      fillColor: AppColors.surface,
    ),
  );

  Widget _unitField(List<ProductUnit> units) => DropdownButtonFormField<String>(
    initialValue: _unitId,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Satuan Recipe',
      filled: true,
      fillColor: AppColors.surface,
    ),
    items: units
        .map(
          (unit) => DropdownMenuItem(
            value: unit.id,
            child: Text(unit.label, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: _busy ? null : (value) => setState(() => _unitId = value),
  );

  Future<void> _addRecipe() async {
    final inventory = _selectedInventory;
    final unit = _availableUnits
        .where((unit) => unit.id == _unitId)
        .firstOrNull;
    final quantity = num.tryParse(_quantityController.text.trim());
    if (inventory == null || unit == null) return;
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      setState(() => _errorMessage = 'Masukkan jumlah resep lebih dari 0.');
      return;
    }
    final conversionFactor = _conversionFactor(inventory.unit, unit);
    if (conversionFactor == null) {
      setState(
        () => _errorMessage =
            'Satuan resep tidak kompatibel dengan satuan stok bahan.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final success = await widget.onAdd(
      inventoryId: inventory.id,
      quantity: quantity,
      unitId: unit.id,
      conversionFactor: conversionFactor,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (success) {
        _recipes.add(
          ProductRecipe(
            inventoryId: inventory.id,
            inventoryName: inventory.name,
            quantity: quantity,
            unitId: unit.id,
            unitName: unit.name,
            unitAbbreviation: unit.abbreviation,
            conversionFactor: conversionFactor,
          ),
        );
        _quantityController.clear();
      } else {
        _errorMessage = 'Bahan gagal disimpan. Periksa koneksi dan coba lagi.';
      }
    });
  }

  Future<void> _removeRecipe(int index) async {
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final success = await widget.onRemove(index);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (success) {
        _recipes.removeAt(index);
      } else {
        _errorMessage = 'Bahan gagal dihapus. Coba lagi.';
      }
    });
  }
}

class _RecipeMessage extends StatelessWidget {
  const _RecipeMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6E5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.warning)),
  );
}

num? _conversionFactor(ProductUnit stockUnit, ProductUnit recipeUnit) {
  if (stockUnit.id == recipeUnit.id) return 1;
  final stock = _unitScale(stockUnit.abbreviation);
  final recipe = _unitScale(recipeUnit.abbreviation);
  if (stock == null || recipe == null || stock.dimension != recipe.dimension) {
    return null;
  }
  return recipe.scale / stock.scale;
}

({String dimension, num scale})? _unitScale(String abbreviation) {
  final unit = abbreviation.trim().toLowerCase();
  return switch (unit) {
    'mg' => (dimension: 'mass', scale: .001),
    'g' || 'gr' => (dimension: 'mass', scale: 1),
    'kg' => (dimension: 'mass', scale: 1000),
    'ml' => (dimension: 'volume', scale: 1),
    'l' || 'lt' => (dimension: 'volume', scale: 1000),
    'pcs' || 'pc' || 'buah' || 'unit' => (dimension: 'count', scale: 1),
    _ => null,
  };
}
