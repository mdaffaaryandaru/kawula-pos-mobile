import '../../../products/data/models/catalog_models.dart';
import '../../../products/domain/entities/catalog_product.dart';
import '../../domain/entities/product_management.dart';

class ManagedProductModel extends ManagedProduct {
  const ManagedProductModel({
    required super.product,
    required super.variantGroupIds,
  });

  factory ManagedProductModel.fromJson(Map<String, dynamic> json) {
    final variantGroups = json['variant_groups'];
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
    );
  }
}

class ManagedVariantGroupModel extends ManagedVariantGroup {
  const ManagedVariantGroupModel({
    required super.id,
    required super.name,
    required super.group,
  });

  factory ManagedVariantGroupModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Data grup varian dari server tidak valid.');
    }
    final options = json['options'];
    if (options is! List) {
      throw const FormatException('Data grup varian dari server tidak valid.');
    }
    return ManagedVariantGroupModel(
      id: id,
      name: name,
      group: ProductVariantGroup(
        name: name,
        isRequired: json['is_required'] == true,
        minSelection: _integer(json['min_selection'], 0),
        maxSelection: _integer(json['max_selection'], 1),
        options: options
            .map((option) {
              if (option is! Map<String, dynamic> ||
                  option['name'] is! String) {
                throw const FormatException(
                  'Opsi grup varian dari server tidak valid.',
                );
              }
              final adjustment = option['price_adjustment'] ?? 0;
              if (adjustment is! num) {
                throw const FormatException(
                  'Penyesuaian harga varian dari server tidak valid.',
                );
              }
              final optionId = option['_id'] ?? option['id'];
              return ProductVariantOption(
                id: optionId is String ? optionId : null,
                name: option['name'] as String,
                priceAdjustment: adjustment,
              );
            })
            .toList(growable: false),
      ),
    );
  }

  static int _integer(Object? value, int fallback) =>
      value is num ? value.toInt() : fallback;
}
