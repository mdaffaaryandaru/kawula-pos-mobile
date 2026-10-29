import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../categories/domain/entities/managed_category.dart';
import '../../../inventories/domain/entities/inventory_item.dart';
import '../../../product_units/domain/entities/product_unit.dart';
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
    required this.inventories,
    required this.productUnits,
    this.errorMessage,
  });

  final List<ManagedProduct> products;
  final List<ManagedCategory> categories;
  final List<ManagedVariantGroup> variantGroups;
  final List<InventoryItem> inventories;
  final List<ProductUnit> productUnits;
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
    String? discountId,
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
        discountId: discountId,
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

  Future<bool> addRecipe({
    required String productId,
    required String inventoryId,
    required num quantity,
    required String unitId,
    required num conversionFactor,
  }) async {
    try {
      await _repository.addRecipe(
        productId: productId,
        inventoryId: inventoryId,
        quantity: quantity,
        unitId: unitId,
        conversionFactor: conversionFactor,
      );
      emit(await _loadData());
      return true;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<bool> removeRecipe({
    required String productId,
    required int recipeIndex,
  }) async {
    try {
      await _repository.removeRecipe(
        productId: productId,
        recipeIndex: recipeIndex,
      );
      emit(await _loadData());
      return true;
    } catch (error) {
      _emitOperationError(error);
      return false;
    }
  }

  Future<ProductManagementLoaded> _loadData() async {
    final products = await _repository.getProducts();
    final errors = <String>[];
    var categories = <ManagedCategory>[];
    var variantGroups = <ManagedVariantGroup>[];
    var inventories = <InventoryItem>[];
    var productUnits = <ProductUnit>[];
    try {
      categories = await _repository.getCategories();
    } catch (error) {
      errors.add('Kategori: ${_messageFor(error)}');
    }
    try {
      variantGroups = await _repository.getVariantGroups();
    } catch (error) {
      errors.add('Grup varian: ${_messageFor(error)}');
    }
    try {
      inventories = await _repository.getInventories();
    } catch (error) {
      errors.add('Bahan inventori: ${_messageFor(error)}');
    }
    try {
      productUnits = await _repository.getProductUnits();
    } catch (error) {
      errors.add('Satuan bahan: ${_messageFor(error)}');
    }
    return ProductManagementLoaded(
      products: products,
      categories: categories,
      variantGroups: variantGroups,
      inventories: inventories,
      productUnits: productUnits,
      errorMessage: errors.isEmpty ? null : errors.join('\n'),
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
          inventories: currentState.inventories,
          productUnits: currentState.productUnits,
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
