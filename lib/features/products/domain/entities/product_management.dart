import '../../../products/domain/entities/catalog_product.dart';

class ManagedProduct {
  const ManagedProduct({required this.product, required this.variantGroupIds});

  final CatalogProduct product;
  final List<String> variantGroupIds;
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
