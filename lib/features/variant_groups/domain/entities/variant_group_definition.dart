class VariantGroupDefinition {
  const VariantGroupDefinition({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.minSelection,
    required this.maxSelection,
    required this.options,
  });

  final String id;
  final String name;
  final bool isRequired;
  final int minSelection;
  final int maxSelection;
  final List<VariantOptionDefinition> options;
}

class VariantOptionDefinition {
  const VariantOptionDefinition({
    required this.name,
    required this.priceAdjustment,
    required this.recipes,
  });

  final String name;
  final num priceAdjustment;
  final List<VariantRecipeDefinition> recipes;
}

class VariantRecipeDefinition {
  const VariantRecipeDefinition({
    required this.inventoryId,
    required this.inventoryName,
    required this.quantity,
    required this.unitId,
    required this.unitName,
    required this.conversionFactor,
  });

  final String inventoryId;
  final String inventoryName;
  final num quantity;
  final String unitId;
  final String unitName;
  final num conversionFactor;
}

class VariantRecipeReferences {
  const VariantRecipeReferences({
    required this.inventories,
    required this.units,
  });

  final List<VariantRecipeReference> inventories;
  final List<VariantRecipeReference> units;
}

class VariantRecipeReference {
  const VariantRecipeReference({required this.id, required this.name});

  final String id;
  final String name;
}
