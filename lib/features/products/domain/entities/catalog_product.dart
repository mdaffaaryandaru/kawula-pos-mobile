class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;
}

class ProductDiscount {
  const ProductDiscount({required this.type, required this.value});

  final String type;
  final num value;
}

class ProductVariantOption {
  const ProductVariantOption({
    required this.name,
    required this.priceAdjustment,
    this.id,
  });

  final String? id;
  final String name;
  final num priceAdjustment;
}

class ProductVariantGroup {
  const ProductVariantGroup({
    required this.name,
    required this.isRequired,
    required this.minSelection,
    required this.maxSelection,
    required this.options,
  });

  final String name;
  final bool isRequired;
  final int minSelection;
  final int maxSelection;
  final List<ProductVariantOption> options;
}

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isActive,
    required this.category,
    required this.variantGroups,
    this.stock,
    this.discount,
  });

  final String id;
  final String name;
  final num price;
  final String imageUrl;
  final bool isActive;
  final ProductCategory? category;
  final List<ProductVariantGroup> variantGroups;
  final num? stock;
  final ProductDiscount? discount;

  num get discountedPrice {
    final activeDiscount = discount;
    if (activeDiscount == null) return price;
    if (activeDiscount.type == 'nominal') {
      return (price - activeDiscount.value).clamp(0, price);
    }
    if (activeDiscount.type == 'percentage') {
      return (price - (price * activeDiscount.value / 100)).clamp(0, price);
    }
    return price;
  }
}

class SelectedProductVariant {
  const SelectedProductVariant({
    required this.groupName,
    required this.optionName,
    this.optionId,
    required this.priceAdjustment,
  });

  final String groupName;
  final String optionName;
  final String? optionId;
  final num priceAdjustment;
}
