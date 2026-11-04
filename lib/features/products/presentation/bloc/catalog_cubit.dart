// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/products/presentation/bloc/catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repository) : super(const CatalogLoading());

  final CatalogRepository _repository;
  Future<void>? _refreshInProgress;

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

  Future<void> refreshProducts() async {
    if (state is! CatalogLoaded) return;
    try {
      final products = await _repository.getProducts();
      final currentState = state;
      if (currentState is CatalogLoaded) {
        emit(currentState.copyWith(products: products));
      }
    } catch (error) {
      emit(CatalogFailure(_messageFor(error)));
    }
  }

  Future<void> refresh() {
    final inProgress = _refreshInProgress;
    if (inProgress != null) return inProgress;
    if (state is! CatalogLoaded) return Future<void>.value();

    final future = _refresh();
    _refreshInProgress = future;
    return future.whenComplete(() {
      if (identical(_refreshInProgress, future)) {
        _refreshInProgress = null;
      }
    });
  }

  Future<void> _refresh() async {
    try {
      final (products, categories) = await (
        _repository.getProducts(),
        _repository.getCategories(),
      ).wait;
      final currentState = state;
      if (currentState is CatalogLoaded) {
        emit(currentState.copyWith(products: products, categories: categories));
      }
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
