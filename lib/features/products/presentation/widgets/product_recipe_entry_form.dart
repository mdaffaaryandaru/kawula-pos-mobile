// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:kawula_pos/features/inventories/domain/entities/inventory_item.dart';
import 'package:kawula_pos/features/product_units/domain/entities/product_unit.dart';
import 'package:kawula_pos/features/products/presentation/widgets/product_management_helpers.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class ProductRecipeEntryForm extends StatelessWidget {
  const ProductRecipeEntryForm({
    super.key,
    required this.inventories,
    required this.inventory,
    required this.inventoryId,
    required this.units,
    required this.unitId,
    required this.quantityController,
    required this.isBusy,
    required this.onInventoryChanged,
    required this.onUnitChanged,
    required this.onAdd,
  });

  final List<InventoryItem> inventories;
  final InventoryItem? inventory;
  final String? inventoryId;
  final List<ProductUnit> units;
  final String? unitId;
  final TextEditingController quantityController;
  final bool isBusy;
  final ValueChanged<String?> onInventoryChanged;
  final ValueChanged<String?> onUnitChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
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
                    Expanded(child: _unitField()),
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
                      Expanded(child: _unitField()),
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
                            '${inventory!.unit.label}.',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: isBusy || inventory == null || unitId == null
                    ? null
                    : onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: isBusy
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
    initialValue: inventoryId,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Bahan Inventory',
      filled: true,
      fillColor: AppColors.surface,
    ),
    items: inventories
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
    onChanged: isBusy ? null : onInventoryChanged,
  );

  Widget _quantityField() => TextField(
    controller: quantityController,
    enabled: !isBusy,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    decoration: const InputDecoration(
      labelText: 'Jumlah Recipe',
      hintText: 'Mis. 15',
      filled: true,
      fillColor: AppColors.surface,
    ),
  );

  Widget _unitField() => DropdownButtonFormField<String>(
    initialValue: unitId,
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
    onChanged: isBusy ? null : onUnitChanged,
  );
}
