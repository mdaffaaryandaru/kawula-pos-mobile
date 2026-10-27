import '../entities/managed_category.dart';

abstract interface class CategoriesRepository {
  Future<List<ManagedCategory>> getCategories();

  Future<ManagedCategory> saveCategory({
    String? categoryId,
    required String name,
    required String description,
    required bool isActive,
  });

  Future<void> deleteCategory(String categoryId);
}
