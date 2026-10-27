import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';

void main() {
  late CartCubit cart;
  const coffee = CatalogProduct(
    id: 'coffee-id',
    name: 'Kopi Susu',
    price: 20000,
    imageUrl: '',
    isActive: true,
    category: null,
    variantGroups: [],
    discount: ProductDiscount(type: 'percentage', value: 10),
  );

  setUp(() {
    cart = CartCubit();
  });

  tearDown(() async {
    await cart.close();
  });

  test('adds same product and selection as one quantity row', () {
    cart
      ..addProduct(coffee)
      ..addProduct(coffee);

    expect(cart.state.items, hasLength(1));
    expect(cart.state.totalQuantity, 2);
    expect(cart.state.estimatedSubtotal, 36000);
  });

  test('keeps different variant selections as separate cart rows', () {
    cart
      ..addProduct(
        coffee,
        selectedVariants: const [
          SelectedProductVariant(
            groupName: 'Ukuran',
            optionName: 'Besar',
            optionId: 'large',
            priceAdjustment: 5000,
          ),
        ],
      )
      ..addProduct(
        coffee,
        selectedVariants: const [
          SelectedProductVariant(
            groupName: 'Ukuran',
            optionName: 'Kecil',
            optionId: 'small',
            priceAdjustment: 0,
          ),
        ],
      );

    expect(cart.state.items, hasLength(2));
    expect(cart.state.estimatedSubtotal, 41000);
  });

  test('removes an item when its quantity is decremented to zero', () {
    cart.addProduct(coffee);
    cart.decrement(cart.state.items.single.selectionKey);

    expect(cart.state.isEmpty, isTrue);
  });
}
