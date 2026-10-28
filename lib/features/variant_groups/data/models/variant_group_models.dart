import '../../domain/entities/variant_group_definition.dart';

class VariantGroupDefinitionModel extends VariantGroupDefinition {
  const VariantGroupDefinitionModel({
    required super.id,
    required super.name,
    required super.isRequired,
    required super.minSelection,
    required super.maxSelection,
    required super.options,
  });

  factory VariantGroupDefinitionModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final options = json['options'];
    if (id is! String || name is! String || options is! List) {
      throw const FormatException('Data grup varian dari server tidak valid.');
    }
    return VariantGroupDefinitionModel(
      id: id,
      name: name,
      isRequired: json['is_required'] == true,
      minSelection: _integer(json['min_selection'], 0),
      maxSelection: _integer(json['max_selection'], 1),
      options: options
          .map((option) {
            if (option is! Map<String, dynamic> || option['name'] is! String) {
              throw const FormatException(
                'Opsi grup varian dari server tidak valid.',
              );
            }
            final priceAdjustment = option['price_adjustment'] ?? 0;
            final recipes = option['recipes'] ?? const [];
            if (priceAdjustment is! num || recipes is! List) {
              throw const FormatException(
                'Opsi grup varian dari server tidak valid.',
              );
            }
            return VariantOptionDefinition(
              name: option['name'] as String,
              priceAdjustment: priceAdjustment,
              recipes: recipes
                  .map((recipe) {
                    if (recipe is! Map<String, dynamic>) {
                      throw const FormatException(
                        'Resep opsi varian dari server tidak valid.',
                      );
                    }
                    return _parseRecipe(recipe);
                  })
                  .toList(growable: false),
            );
          })
          .toList(growable: false),
    );
  }

  static VariantRecipeDefinition _parseRecipe(Map<String, dynamic> json) {
    final inventoryValue = json['inventory_id'];
    final unitValue = json['unit_id'];
    final inventoryId = _referenceId(inventoryValue);
    final inventoryName = _referenceName(inventoryValue);
    final unitId = _referenceId(unitValue);
    final unitName = _referenceName(unitValue);
    final quantity = json['quantity'];
    final conversionFactor = json['conversion_factor'];
    if (inventoryId == null ||
        unitId == null ||
        quantity is! num ||
        conversionFactor is! num) {
      throw const FormatException(
        'Resep opsi varian dari server tidak lengkap.',
      );
    }
    return VariantRecipeDefinition(
      inventoryId: inventoryId,
      inventoryName: inventoryName ?? 'Bahan',
      quantity: quantity,
      unitId: unitId,
      unitName: unitName ?? 'Satuan',
      conversionFactor: conversionFactor,
    );
  }

  static String? _referenceId(Object? value) {
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final id = value['_id'] ?? value['id'];
      return id is String ? id : null;
    }
    return null;
  }

  static String? _referenceName(Object? value) =>
      value is Map<String, dynamic> && value['name'] is String
      ? value['name'] as String
      : null;
}

class VariantRecipeReferenceModel extends VariantRecipeReference {
  const VariantRecipeReferenceModel({required super.id, required super.name});

  factory VariantRecipeReferenceModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    if (id is! String || name is! String) {
      throw const FormatException(
        'Data referensi resep grup varian dari server tidak valid.',
      );
    }
    return VariantRecipeReferenceModel(id: id, name: name);
  }
}

int _integer(Object? value, int fallback) =>
    value is num ? value.toInt() : fallback;
