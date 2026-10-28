import '../../../products/data/models/catalog_models.dart';
import '../../../inventories/data/models/inventory_models.dart';
import '../../domain/entities/product_management.dart';

class ManagedProductModel extends ManagedProduct {
  const ManagedProductModel({
    required super.product,
    required super.variantGroupIds,
    required super.recipes,
  });

  factory ManagedProductModel.fromJson(Map<String, dynamic> json) {
    final variantGroups = json['variant_groups'];
    final recipes = json['recipes'];
    final variantGroupIds = <String>[];
    if (variantGroups is List) {
      for (final item in variantGroups) {
        if (item is String) {
          variantGroupIds.add(item);
        } else if (item is Map<String, dynamic>) {
          final id = item['_id'] ?? item['id'];
          if (id is String) variantGroupIds.add(id);
        }
      }
    }
    return ManagedProductModel(
      product: CatalogProductModel.fromJson(json),
      variantGroupIds: variantGroupIds,
      recipes: recipes is List
          ? recipes
                .map((item) {
                  if (item is! Map<String, dynamic>) {
                    throw const FormatException(
                      'Data bahan resep produk tidak valid.',
                    );
                  }
                  return ProductRecipeModel.fromJson(item);
                })
                .toList(growable: false)
          : const [],
    );
  }
}
