import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';

void main() {
  const product = CatalogProduct(
    id: 'coffee',
    name: 'Kopi',
    price: 10000,
    imageUrl: '',
    isActive: true,
    category: null,
    variantGroups: [],
    stock: 10,
  );

  test(
    'selection key distinguishes equal option names in different groups',
    () {
      const size = SelectedProductVariant(
        groupName: 'Ukuran',
        optionName: 'Normal',
        priceAdjustment: 0,
      );
      const sweetness = SelectedProductVariant(
        groupName: 'Gula',
        optionName: 'Normal',
        priceAdjustment: 0,
      );

      final sizeKey = CartItem(
        product: product,
        quantity: 1,
        selectedVariants: const [size],
      ).selectionKey;
      final sweetnessKey = CartItem(
        product: product,
        quantity: 1,
        selectedVariants: const [sweetness],
      ).selectionKey;

      expect(sizeKey, isNot(sweetnessKey));
    },
  );

  test(
    'identical selections have a stable key and merge in the cart',
    () async {
      const size = SelectedProductVariant(
        groupName: 'Ukuran',
        optionName: 'Besar',
        optionId: 'large',
        priceAdjustment: 5000,
      );
      const temperature = SelectedProductVariant(
        groupName: 'Suhu',
        optionName: 'Dingin',
        optionId: 'cold',
        priceAdjustment: 0,
      );
      final first = CartItem(
        product: product,
        quantity: 1,
        selectedVariants: const [size, temperature],
      );
      final reordered = CartItem(
        product: product,
        quantity: 1,
        selectedVariants: const [temperature, size],
      );
      final cart = CartCubit();
      addTearDown(cart.close);

      cart
        ..addProduct(product, selectedVariants: const [size, temperature])
        ..addProduct(product, selectedVariants: const [temperature, size]);

      expect(first.selectionKey, reordered.selectionKey);
      expect(cart.state.items, hasLength(1));
      expect(cart.state.items.single.quantity, 2);
    },
  );

  test('uses group and option name when option ID is absent', () {
    const sugar = SelectedProductVariant(
      groupName: 'Gula',
      optionName: 'Normal',
      priceAdjustment: 0,
    );
    const milk = SelectedProductVariant(
      groupName: 'Susu',
      optionName: 'Normal',
      priceAdjustment: 0,
    );
    const lessSugar = SelectedProductVariant(
      groupName: 'Gula',
      optionName: 'Kurang',
      priceAdjustment: 0,
    );
    final sugarKey = CartItem(
      product: product,
      quantity: 1,
      selectedVariants: const [sugar],
    ).selectionKey;
    final milkKey = CartItem(
      product: product,
      quantity: 1,
      selectedVariants: const [milk],
    ).selectionKey;
    final lessSugarKey = CartItem(
      product: product,
      quantity: 1,
      selectedVariants: const [lessSugar],
    ).selectionKey;

    expect(sugarKey, contains('Gula:Normal'));
    expect(milkKey, contains('Susu:Normal'));
    expect(sugarKey, isNot(milkKey));
    expect(lessSugarKey, contains('Gula:Kurang'));
    expect(sugarKey, isNot(lessSugarKey));
  });

  test(
    'increment and decrement only affect the matching variant group',
    () async {
      const size = SelectedProductVariant(
        groupName: 'Ukuran',
        optionName: 'Normal',
        priceAdjustment: 0,
      );
      const sweetness = SelectedProductVariant(
        groupName: 'Gula',
        optionName: 'Normal',
        priceAdjustment: 0,
      );
      final cart = CartCubit();
      addTearDown(cart.close);
      cart
        ..addProduct(product, selectedVariants: const [size])
        ..addProduct(product, selectedVariants: const [sweetness]);

      expect(cart.state.items, hasLength(2));
      cart.increment(cart.state.items.first.selectionKey);
      expect(cart.state.items.map((item) => item.quantity), [2, 1]);
      cart.decrement(cart.state.items.first.selectionKey);
      expect(cart.state.items.map((item) => item.quantity), [1, 1]);
    },
  );
}
