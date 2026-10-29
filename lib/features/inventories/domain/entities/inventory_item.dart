import '../../../product_units/domain/entities/product_unit.dart';

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
    this.maxStock,
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
  final num? maxStock;
}

class InventoryMutation {
  const InventoryMutation({
    required this.id,
    required this.type,
    required this.quantity,
    required this.currentStock,
    required this.notes,
    required this.createdAt,
    this.createdBy,
    this.relatedProductName,
  });

  final String id;
  final String type;
  final num quantity;
  final num currentStock;
  final String notes;
  final DateTime? createdAt;
  final String? createdBy;
  final String? relatedProductName;
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
