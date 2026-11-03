// Project imports:
import 'package:kawula_pos/features/inventories/domain/entities/inventory_item.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';

class ManagedProduct {
  const ManagedProduct({
    required this.product,
    required this.variantGroupIds,
    this.recipes = const [],
  });

  final CatalogProduct product;
  final List<String> variantGroupIds;
  final List<ProductRecipe> recipes;
}

class ManagedVariantGroup {
  const ManagedVariantGroup({
    required this.id,
    required this.name,
    required this.group,
  });

  final String id;
  final String name;
  final ProductVariantGroup group;
}
