import '../../domain/entities/managed_category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_remote_data_source.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl(this._remoteDataSource);

  final CategoriesRemoteDataSource _remoteDataSource;

  @override
  Future<List<ManagedCategory>> getCategories() =>
      _remoteDataSource.getCategories();

  @override
  Future<ManagedCategory> saveCategory({
    String? categoryId,
    required String name,
    required String description,
    required bool isActive,
  }) {
    return _remoteDataSource.saveCategory(
      categoryId: categoryId,
      name: name,
      description: description,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteCategory(String categoryId) =>
      _remoteDataSource.deleteCategory(categoryId);
}
