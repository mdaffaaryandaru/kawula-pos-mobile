import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/discounts/domain/entities/discount_definition.dart';
import 'package:kawula_pos/features/discounts/domain/repositories/discounts_repository.dart';
import 'package:kawula_pos/features/discounts/presentation/pages/discounts_management_page.dart';

void main() {
  testWidgets('lists discounts and filters by query and type', (tester) async {
    final repository = _FakeDiscountsRepository();
    await tester.pumpWidget(
      MaterialApp(home: DiscountsManagementPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('NAMA'), findsOneWidget);
    expect(find.text('Happy Hour'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
    expect(find.text('Rp 10.000'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hour');
    await tester.pumpAndSettle();
    expect(find.text('Happy Hour'), findsOneWidget);
    expect(find.text('Member'), findsNothing);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semua Tipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nominal').last);
    await tester.pumpAndSettle();
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Happy Hour'), findsNothing);
  });

  testWidgets('creates, edits, and confirms discount deletion', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeDiscountsRepository(discounts: []);
    await tester.pumpWidget(
      MaterialApp(home: DiscountsManagementPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada discount.'), findsOneWidget);
    await tester.tap(find.text('Tambah Discount').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Promo Baru');
    await tester.enterText(find.byType(TextFormField).at(1), '20');
    await tester.enterText(find.byType(TextFormField).at(2), 'Diskon menu');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(repository.discounts.single.name, 'Promo Baru');
    expect(repository.discounts.single.type, DiscountType.percentage);
    expect(find.text('Promo Baru'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '25000');
    await tester.tap(find.byType(DropdownButtonFormField<DiscountType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nominal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(repository.discounts.single.type, DiscountType.nominal);
    expect(repository.discounts.single.value, 25000);

    await tester.tap(find.byTooltip('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Discount "Promo Baru" akan dihapus.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();
    expect(repository.discounts, isEmpty);
    expect(find.text('Belum ada discount.'), findsOneWidget);
  });
}

class _FakeDiscountsRepository implements DiscountsRepository {
  _FakeDiscountsRepository({List<DiscountDefinition>? discounts})
    : discounts =
          discounts ??
          [
            const DiscountDefinition(
              id: 'happy-hour',
              name: 'Happy Hour',
              type: DiscountType.percentage,
              value: 15,
              description: 'Diskon sore',
              isActive: true,
            ),
            const DiscountDefinition(
              id: 'member',
              name: 'Member',
              type: DiscountType.nominal,
              value: 10000,
              description: 'Potongan pelanggan',
              isActive: false,
            ),
          ];

  final List<DiscountDefinition> discounts;
  var _nextId = 0;

  @override
  Future<List<DiscountDefinition>> getDiscounts() async =>
      List.unmodifiable(discounts);

  @override
  Future<DiscountDefinition> saveDiscount({
    String? discountId,
    required String name,
    required DiscountType type,
    required num value,
    required String description,
    required bool isActive,
  }) async {
    final discount = DiscountDefinition(
      id: discountId ?? 'new-${_nextId++}',
      name: name,
      type: type,
      value: value,
      description: description,
      isActive: isActive,
    );
    discounts.removeWhere((item) => item.id == discount.id);
    discounts.add(discount);
    return discount;
  }

  @override
  Future<void> deleteDiscount(String discountId) async {
    discounts.removeWhere((discount) => discount.id == discountId);
  }
}
