import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/catalog_product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    required this.selectedVariants,
    this.notes = '',
  });

  final CatalogProduct product;
  final int quantity;
  final List<SelectedProductVariant> selectedVariants;
  final String notes;

  num get unitPrice =>
      product.discountedPrice +
      selectedVariants.fold<num>(
        0,
        (total, variant) => total + variant.priceAdjustment,
      );

  String get selectionKey {
    final variants = [...selectedVariants]
      ..sort((a, b) {
        final group = a.groupName.compareTo(b.groupName);
        return group != 0 ? group : a.optionName.compareTo(b.optionName);
      });
    return '${product.id}|${variants.map((variant) => '${variant.groupName}:${variant.optionId ?? variant.optionName}').join('|')}';
  }
}

class CartState {
  const CartState(this.items);

  final List<CartItem> items;

  int get totalQuantity =>
      items.fold(0, (total, item) => total + item.quantity);

  num get estimatedSubtotal =>
      items.fold(0, (total, item) => total + item.unitPrice * item.quantity);

  bool get isEmpty => items.isEmpty;
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState([]));

  void addProduct(
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
  }

  void increment(String selectionKey) {
    _updateQuantity(selectionKey, 1);
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

  void _updateQuantity(String selectionKey, int change) {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.selectionKey == selectionKey);
    if (index == -1) return;

    final item = items[index];
    final quantity = item.quantity + change;
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
  }
}
