import '../../domain/entities/catalog_product.dart';

sealed class CatalogState {
  const CatalogState();
}

final class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

final class CatalogLoaded extends CatalogState {
  const CatalogLoaded({
    required this.products,
    required this.categories,
    this.selectedCategoryId,
    this.searchQuery = '',
  });

  final List<CatalogProduct> products;
  final List<ProductCategory> categories;
  final String? selectedCategoryId;
  final String searchQuery;

  List<CatalogProduct> get visibleProducts {
    final query = searchQuery.trim().toLowerCase();
    return products.where((product) {
      final matchesCategory =
          selectedCategoryId == null ||
          product.category?.id == selectedCategoryId;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.category?.name.toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  CatalogLoaded copyWith({
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
  }) {
    return CatalogLoaded(
      products: products,
      categories: categories,
      selectedCategoryId: clearCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final class CatalogFailure extends CatalogState {
  const CatalogFailure(this.message);

  final String message;
}
