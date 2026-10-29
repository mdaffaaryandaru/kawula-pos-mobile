import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/categories/domain/entities/managed_category.dart';
import 'package:kawula_pos/features/discounts/domain/entities/discount_definition.dart';
import 'package:kawula_pos/features/products/presentation/dialogs/product_dialog.dart';

void main() {
  testWidgets('starts without discount and saves the selected discount', (
    tester,
  ) async {
    late Future<ProductDraft?> draft;
    const categories = [
      ManagedCategory(
        id: 'category-id',
        name: 'Minuman',
        description: '',
        isActive: true,
      ),
    ];
    const discounts = [
      DiscountDefinition(
        id: 'discount-id',
        name: 'Happy Hour',
        type: DiscountType.percentage,
        value: 10,
        description: '',
        isActive: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => draft = showDialog<ProductDraft>(
                context: context,
                builder: (_) => const ProductDialog(
                  categories: categories,
                  variantGroups: [],
                  discounts: discounts,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Tanpa Discounts'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama produk'),
      'Kopi',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '18000');
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Happy Hour (10%)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan produk'));
    await tester.pumpAndSettle();

    expect((await draft)?.discountId, 'discount-id');
  });
}
