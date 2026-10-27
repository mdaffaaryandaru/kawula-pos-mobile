import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/catalog_repository.dart';
import 'catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repository) : super(const CatalogLoading());

  final CatalogRepository _repository;

  Future<void> load() async {
    emit(const CatalogLoading());
    try {
      final products = await _repository.getProducts();
      final categories = await _repository.getCategories();
      emit(CatalogLoaded(products: products, categories: categories));
    } catch (error) {
      emit(CatalogFailure(_messageFor(error)));
    }
  }

  void selectCategory(String? categoryId) {
    final currentState = state;
    if (currentState is! CatalogLoaded) return;
    emit(
      currentState.copyWith(
        selectedCategoryId: categoryId,
        clearCategory: categoryId == null,
      ),
    );
  }

  void search(String query) {
    final currentState = state;
    if (currentState is! CatalogLoaded) return;
    emit(currentState.copyWith(searchQuery: query));
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
