import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/inventories/domain/entities/inventory_item.dart';
import 'package:kawula_pos/features/inventories/domain/repositories/inventory_repository.dart';
import 'package:kawula_pos/features/inventories/presentation/pages/inventories_management_page.dart';
import 'package:kawula_pos/features/product_units/domain/entities/product_unit.dart';
import 'package:kawula_pos/features/product_units/domain/repositories/product_units_repository.dart';

void main() {
  testWidgets('shows inventory table and filters items by search', (
    tester,
  ) async {
    final repository = _FakeInventoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: InventoriesManagementPage(
          repository: repository,
          productUnitsRepository: _FakeProductUnitsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NAMA BAHAN'), findsOneWidget);
    expect(find.text('Kopi Arabika'), findsOneWidget);
    expect(find.text('Susu'), findsOneWidget);
    expect(find.text('Rp 18.000'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'arabika');
    await tester.pumpAndSettle();

    expect(find.text('Kopi Arabika'), findsOneWidget);
    expect(find.text('Susu'), findsNothing);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('Kopi Arabika'), findsOneWidget);
    expect(find.text('Susu'), findsOneWidget);
  });
}

class _FakeInventoryRepository implements InventoryRepository {
  final List<InventoryItem> items = [
    const InventoryItem(
      id: 'coffee',
      name: 'Kopi Arabika',
      stock: 1200,
      unit: ProductUnit(id: 'gram', name: 'Gram', abbreviation: 'g'),
      isActive: true,
      category: 'Biji kopi',
      buyPrice: 125000,
      minStock: 500,
    ),
    const InventoryItem(
      id: 'milk',
      name: 'Susu',
      stock: 3,
      unit: ProductUnit(id: 'liter', name: 'Liter', abbreviation: 'L'),
      isActive: true,
      category: 'Dairy',
      buyPrice: 18000,
      minStock: 1,
    ),
  ];

  @override
  Future<List<InventoryItem>> getInventories() async => items;

  @override
  Future<void> saveInventory({
    String? inventoryId,
    required String name,
    required num? stock,
    required String unitId,
    required String category,
    required String description,
    required num buyPrice,
    required num minStock,
    required num? maxStock,
    required bool isActive,
  }) async {}

  @override
  Future<void> deleteInventory(String inventoryId) async {}

  @override
  Future<void> adjustStock({
    required String inventoryId,
    required String type,
    required num quantity,
    required String notes,
  }) async {}

  @override
  Future<List<InventoryMutation>> getMutations(String inventoryId) async => [];
}

class _FakeProductUnitsRepository implements ProductUnitsRepository {
  @override
  Future<List<ProductUnit>> getProductUnits() async => const [
    ProductUnit(id: 'gram', name: 'Gram', abbreviation: 'g'),
    ProductUnit(id: 'liter', name: 'Liter', abbreviation: 'L'),
  ];

  @override
  Future<ProductUnit> saveProductUnit({
    String? unitId,
    required String name,
    required String abbreviation,
    required String description,
    required bool isActive,
  }) async => ProductUnit(
    id: unitId ?? 'new-unit',
    name: name,
    abbreviation: abbreviation,
    description: description,
    isActive: isActive,
  );

  @override
  Future<void> deleteProductUnit(String unitId) async {}
}
