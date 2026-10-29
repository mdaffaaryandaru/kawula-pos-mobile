import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/product_units/domain/entities/product_unit.dart';
import 'package:kawula_pos/features/product_units/domain/repositories/product_units_repository.dart';
import 'package:kawula_pos/features/product_units/presentation/pages/product_units_management_page.dart';

void main() {
  testWidgets('lists and locally searches product units', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductUnitsManagementPage(
          repository: _FakeProductUnitsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NAMA'), findsOneWidget);
    expect(find.text('Gram'), findsOneWidget);
    expect(find.text('Kilogram'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kilo');
    await tester.pumpAndSettle();

    expect(find.text('Kilogram'), findsOneWidget);
    expect(find.text('Gram'), findsNothing);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('Kilogram'), findsOneWidget);
    expect(find.text('Gram'), findsOneWidget);
  });
}

class _FakeProductUnitsRepository implements ProductUnitsRepository {
  @override
  Future<List<ProductUnit>> getProductUnits() async => const [
    ProductUnit(
      id: 'gram',
      name: 'Gram',
      abbreviation: 'g',
      description: 'Satuan berat dalam gram',
    ),
    ProductUnit(
      id: 'kilogram',
      name: 'Kilogram',
      abbreviation: 'kg',
      description: 'Satuan berat dalam kilogram',
    ),
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
