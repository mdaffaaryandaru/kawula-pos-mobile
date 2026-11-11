import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';

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
        if (group != 0) return group;
        final aOption = a.optionId ?? a.optionName;
        final bOption = b.optionId ?? b.optionName;
        return aOption.compareTo(bOption);
      });
    return '${product.id}|${variants.map((variant) => '${variant.groupName}:${variant.optionId ?? variant.optionName}').join('|')}';
  }
}
