// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';

class CartState {
  const CartState(this.items);

  final List<CartItem> items;

  int quantityForProduct(String productId) => items
      .where((item) => item.product.id == productId)
      .fold(0, (total, item) => total + item.quantity);

  CartStockIssue? validateProductQuantity(
    CatalogProduct product, {
    required int quantity,
    String? excludingSelectionKey,
  }) {
    final currentQuantity = items
        .where(
          (item) =>
              item.product.id == product.id &&
              item.selectionKey != excludingSelectionKey,
        )
        .fold(0, (total, item) => total + item.quantity);

    switch (product.stockStatus) {
      case ProductStockStatus.available:
        if (currentQuantity + quantity > product.stock!) {
          return CartStockIssue(
            productName: product.name,
            message:
                'Stok ${product.name} tidak mencukupi. '
                'Tersedia ${product.stock} unit, '
                'di keranjang $currentQuantity unit.',
          );
        }
        break;
      case ProductStockStatus.outOfStock:
        return CartStockIssue(
          productName: product.name,
          message: 'Stok ${product.name} habis.',
        );
      case ProductStockStatus.unavailable:
        return CartStockIssue(
          productName: product.name,
          message: 'Stok ${product.name} tidak tersedia.',
        );
    }
    return null;
  }

  List<CartStockIssue> get stockIssues {
    final productItems = <String, CartItem>{};
    for (final item in items) {
      productItems.putIfAbsent(item.product.id, () => item);
    }
    return [
      for (final item in productItems.values)
        ?validateProductQuantity(item.product, quantity: 0),
    ];
  }

  int get totalQuantity =>
      items.fold(0, (total, item) => total + item.quantity);

  num get estimatedSubtotal =>
      items.fold(0, (total, item) => total + item.unitPrice * item.quantity);

  bool get isEmpty => items.isEmpty;
}

class CartStockIssue {
  const CartStockIssue({required this.productName, required this.message});

  final String productName;
  final String message;
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState([]));

  String? addProduct(
    CatalogProduct product, {
    List<SelectedProductVariant> selectedVariants = const [],
  }) {
    final key = CartItem(
      product: product,
      quantity: 1,
      selectedVariants: selectedVariants,
    ).selectionKey;
    final items = [...state.items];
    final index = items.indexWhere((item) => item.selectionKey == key);
    final currentQuantity = index == -1 ? 0 : items[index].quantity;
    final issue = state.validateProductQuantity(
      product,
      quantity: currentQuantity + 1,
      excludingSelectionKey: index == -1 ? null : key,
    );
    if (issue != null) return issue.message;

    if (index == -1) {
      items.add(
        CartItem(
          product: product,
          quantity: 1,
          selectedVariants: List.unmodifiable(selectedVariants),
        ),
      );
    } else {
      final item = items[index];
      items[index] = CartItem(
        product: item.product,
        quantity: item.quantity + 1,
        selectedVariants: item.selectedVariants,
        notes: item.notes,
      );
    }
    emit(CartState(List.unmodifiable(items)));
    return null;
  }

  String? increment(String selectionKey) {
    return _updateQuantity(selectionKey, 1);
  }

  void decrement(String selectionKey) {
    _updateQuantity(selectionKey, -1);
  }

  void remove(String selectionKey) {
    emit(
      CartState(
        List.unmodifiable(
          state.items.where((item) => item.selectionKey != selectionKey),
        ),
      ),
    );
  }

  void updateNotes(String selectionKey, String notes) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.selectionKey == selectionKey);
    if (index == -1) return;
    final item = items[index];
    items[index] = CartItem(
      product: item.product,
      quantity: item.quantity,
      selectedVariants: item.selectedVariants,
      notes: notes,
    );
    emit(CartState(List.unmodifiable(items)));
  }

  void clear() => emit(const CartState([]));

  void updateStockFromProducts(Iterable<CatalogProduct> products) {
    final refreshedProducts = {
      for (final product in products) product.id: product,
    };
    var changed = false;
    final items = state.items
        .map((item) {
          final refreshedProduct = refreshedProducts[item.product.id];
          if (refreshedProduct == null ||
              item.product.stock == refreshedProduct.stock) {
            return item;
          }

          changed = true;
          final product = item.product;
          return CartItem(
            product: CatalogProduct(
              id: product.id,
              name: product.name,
              price: product.price,
              imageUrl: product.imageUrl,
              isActive: product.isActive,
              category: product.category,
              variantGroups: product.variantGroups,
              images: product.images,
              stock: refreshedProduct.stock,
              discount: product.discount,
              discountId: product.discountId,
            ),
            quantity: item.quantity,
            selectedVariants: item.selectedVariants,
            notes: item.notes,
          );
        })
        .toList(growable: false);

    if (changed) emit(CartState(List.unmodifiable(items)));
  }

  String? _updateQuantity(String selectionKey, int change) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.selectionKey == selectionKey);
    if (index == -1) return null;

    final item = items[index];
    final quantity = item.quantity + change;
    if (change > 0) {
      final issue = state.validateProductQuantity(
        item.product,
        quantity: quantity,
        excludingSelectionKey: selectionKey,
      );
      if (issue != null) return issue.message;
    }
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = CartItem(
        product: item.product,
        quantity: quantity,
        selectedVariants: item.selectedVariants,
        notes: item.notes,
      );
    }
    emit(CartState(List.unmodifiable(items)));
    return null;
  }
}
