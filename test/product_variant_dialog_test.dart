import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_variant_dialog.dart';

void main() {
  testWidgets('requires and returns the selected product variant', (
    tester,
  ) async {
    const product = CatalogProduct(
      id: 'coffee-id',
      name: 'Kopi Susu',
      price: 20000,
      imageUrl: '',
      isActive: true,
      category: null,
      variantGroups: [
        ProductVariantGroup(
          name: 'Ukuran',
          isRequired: true,
          minSelection: 1,
          maxSelection: 1,
          options: [
            ProductVariantOption(
              id: 'large-id',
              name: 'Besar',
              priceAdjustment: 5000,
            ),
          ],
        ),
      ],
    );
    List<SelectedProductVariant>? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showProductVariantDialog(context, product);
              },
              child: const Text('Pilih'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambahkan'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih 1–1 opsi.'), findsOneWidget);

    await tester.tap(find.text('Besar'));
    await tester.tap(find.text('Tambahkan'));
    await tester.pumpAndSettle();

    expect(result, hasLength(1));
    expect(result!.single.groupName, 'Ukuran');
    expect(result!.single.optionId, 'large-id');
  });
}
