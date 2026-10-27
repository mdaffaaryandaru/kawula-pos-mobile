import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../categories/domain/entities/managed_category.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../../domain/entities/product_management.dart';
import '../../domain/repositories/product_management_repository.dart';

sealed class ProductManagementState {
  const ProductManagementState();
}

final class ProductManagementLoading extends ProductManagementState {
  const ProductManagementLoading();
}

final class ProductManagementLoaded extends ProductManagementState {
  const ProductManagementLoaded({
    required this.products,
    required this.categories,
    required this.variantGroups,
    this.errorMessage,
  });

  final List<ManagedProduct> products;
  final List<ManagedCategory> categories;
  final List<ManagedVariantGroup> variantGroups;
  final String? errorMessage;
}

final class ProductManagementFailure extends ProductManagementState {
  const ProductManagementFailure(this.message);

  final String message;
}

class ProductManagementCubit extends Cubit<ProductManagementState> {
  ProductManagementCubit(this._repository)
    : super(const ProductManagementLoading());

  final ProductManagementRepository _repository;

  Future<List<String>?> uploadProductImages(List<XFile> images) async {
    try {
      return await _repository.uploadProductImages(images);
    } catch (error) {
      _emitOperationError(error);
      return null;
    }
  }

  Future<void> load() async {
    emit(const ProductManagementLoading());
    try {
      final data = await _loadData();
      emit(data);
    } catch (error) {
      emit(ProductManagementFailure(_messageFor(error)));
    }
  }

  Future<bool> saveProduct({
    String? productId,
    required String name,
    required num price,
    required num stock,
    required String categoryId,
    required List<String> variantGroupIds,
    required List<ProductImage> images,
    required bool isActive,
  }) async {
    try {
      await _repository.saveProduct(
        productId: productId,
        name: name,
        price: price,
        stock: stock,
        categoryId: categoryId,
        variantGroupIds: variantGroupIds,
        images: images,
        isActive: isActive,
      );
      emit(await _loadData());
      return true;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _repository.deleteProduct(productId);
      emit(await _loadData());
      return true;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<ProductManagementLoaded> _loadData() async {
    return ProductManagementLoaded(
      products: await _repository.getProducts(),
      categories: await _repository.getCategories(),
      variantGroups: await _repository.getVariantGroups(),
    );
  }

  void _emitOperationError(Object error) {
    final currentState = state;
    if (currentState is ProductManagementLoaded) {
      emit(
        ProductManagementLoaded(
          products: currentState.products,
          categories: currentState.categories,
          variantGroups: currentState.variantGroups,
          errorMessage: _messageFor(error),
        ),
      );
    } else {
      emit(ProductManagementFailure(_messageFor(error)));
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
