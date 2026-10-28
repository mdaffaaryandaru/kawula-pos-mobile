class ProductUnit {
  const ProductUnit({
    required this.id,
    required this.name,
    required this.abbreviation,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String abbreviation;
  final bool isActive;

  String get label => '$name (${abbreviation.toLowerCase()})';
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.isActive,
    this.category = '',
    this.description = '',
    this.buyPrice = 0,
    this.minStock = 0,
  });

  final String id;
  final String name;
  final num stock;
  final ProductUnit unit;
  final bool isActive;
  final String category;
  final String description;
  final num buyPrice;
  final num minStock;
}

class ProductRecipe {
  const ProductRecipe({
    required this.inventoryId,
    required this.inventoryName,
    required this.quantity,
    required this.unitId,
    required this.unitName,
    required this.unitAbbreviation,
    required this.conversionFactor,
  });

  final String inventoryId;
  final String inventoryName;
  final num quantity;
  final String unitId;
  final String unitName;
  final String unitAbbreviation;
  final num conversionFactor;

  String get quantityLabel =>
      '${_formatQuantity(quantity)} ${unitAbbreviation.toLowerCase()}';

  static String _formatQuantity(num value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toString();
  }
}
