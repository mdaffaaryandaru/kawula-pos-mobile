import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/categories/domain/entities/managed_category.dart';
import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/categories/presentation/pages/categories_management_page.dart';

void main() {
  testWidgets('shows category table and filters by name or description', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoriesManagementPage(repository: _FakeCategoriesRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NAMA'), findsOneWidget);
    expect(find.text('Add On'), findsOneWidget);
    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('Aktif'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'olahan kopi');
    await tester.pumpAndSettle();

    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('Add On'), findsNothing);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('Kopi'), findsOneWidget);
    expect(find.text('Add On'), findsOneWidget);
  });
}

class _FakeCategoriesRepository implements CategoriesRepository {
  @override
  Future<List<ManagedCategory>> getCategories() async => const [
    ManagedCategory(
      id: 'addon',
      name: 'Add On',
      description: 'Tambahan untuk menu',
      isActive: true,
    ),
    ManagedCategory(
      id: 'coffee',
      name: 'Kopi',
      description: 'Aneka olahan kopi panas & dingin',
      isActive: true,
    ),
  ];

  @override
  Future<ManagedCategory> saveCategory({
    String? categoryId,
    required String name,
    required String description,
    required bool isActive,
  }) async => ManagedCategory(
    id: categoryId ?? 'new-category',
    name: name,
    description: description,
    isActive: isActive,
  );

  @override
  Future<void> deleteCategory(String categoryId) async {}
}
