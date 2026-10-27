import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/managed_category.dart';
import '../../domain/repositories/categories_repository.dart';

sealed class CategoriesState {
  const CategoriesState();
}

final class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

final class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded({required this.categories, this.errorMessage});

  final List<ManagedCategory> categories;
  final String? errorMessage;
}

final class CategoriesFailure extends CategoriesState {
  const CategoriesFailure(this.message);

  final String message;
}

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesLoading());

  final CategoriesRepository _repository;

  Future<void> load() async {
    emit(const CategoriesLoading());
    try {
      emit(CategoriesLoaded(categories: await _repository.getCategories()));
    } catch (error) {
      emit(CategoriesFailure(_messageFor(error)));
    }
  }

  Future<bool> saveCategory({
    String? categoryId,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    try {
      await _repository.saveCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        isActive: isActive,
      );
      await load();
      return state is CategoriesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _repository.deleteCategory(categoryId);
      await load();
      return state is CategoriesLoaded;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is CategoriesLoaded) {
      emit(
        CategoriesLoaded(
          categories: currentState.categories,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(CategoriesFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
