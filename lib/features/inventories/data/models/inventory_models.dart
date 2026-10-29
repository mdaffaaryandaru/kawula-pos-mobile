import '../../domain/entities/inventory_item.dart';
import '../../../product_units/data/models/product_unit_model.dart';

class InventoryMutationModel extends InventoryMutation {
  const InventoryMutationModel({
    required super.id,
    required super.type,
    required super.quantity,
    required super.currentStock,
    required super.notes,
    required super.createdAt,
    super.createdBy,
    super.relatedProductName,
  });

  factory InventoryMutationModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final type = json['type'];
    final quantity = json['quantity'];
    final currentStock = json['current_stock'];
    if (id is! String ||
        type is! String ||
        quantity is! num ||
        currentStock is! num) {
      throw const FormatException('Data riwayat stok tidak valid.');
    }
    return InventoryMutationModel(
      id: id,
      type: type,
      quantity: quantity,
      currentStock: currentStock,
      notes: json['notes'] is String ? json['notes'] as String : '',
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      createdBy: _inventoryReferenceName(json['created_by']),
      relatedProductName: _inventoryReferenceName(json['related_product_id']),
    );
  }
}

class InventoryItemModel extends InventoryItem {
  const InventoryItemModel({
    required super.id,
    required super.name,
    required super.stock,
    required super.unit,
    required super.isActive,
    super.category,
    super.description,
    super.buyPrice,
    super.minStock,
    super.maxStock,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final stock = json['stock'];
    final unitJson = json['unit_id'];
    if (id is! String || name is! String || stock is! num) {
      throw const FormatException('Data bahan inventori tidak valid.');
    }
    if (unitJson is! Map<String, dynamic>) {
      throw const FormatException('Satuan bahan inventori tidak tersedia.');
    }
    return InventoryItemModel(
      id: id,
      name: name,
      stock: stock,
      unit: ProductUnitModel.fromJson(unitJson),
      isActive: json['is_active'] != false,
      category: json['category'] is String ? json['category'] as String : '',
      description: json['description'] is String
          ? json['description'] as String
          : '',
      buyPrice: json['buy_price'] is num ? json['buy_price'] as num : 0,
      minStock: json['min_stock'] is num ? json['min_stock'] as num : 0,
      maxStock: json['max_stock'] is num ? json['max_stock'] as num : null,
    );
  }
}

String? _inventoryReferenceName(Object? value) {
  if (value is Map<String, dynamic>) {
    final name = value['name'];
    return name is String ? name : null;
  }
  return null;
}

class ProductRecipeModel extends ProductRecipe {
  const ProductRecipeModel({
    required super.inventoryId,
    required super.inventoryName,
    required super.quantity,
    required super.unitId,
    required super.unitName,
    required super.unitAbbreviation,
    required super.conversionFactor,
  });

  factory ProductRecipeModel.fromJson(Map<String, dynamic> json) {
    final inventory = json['inventory_id'];
    final unit = json['unit_id'];
    final quantity = json['quantity'];
    final conversionFactor = json['conversion_factor'];
    if ((inventory is! Map<String, dynamic> && inventory is! String) ||
        (unit is! Map<String, dynamic> && unit is! String) ||
        quantity is! num ||
        conversionFactor is! num) {
      throw const FormatException('Data resep produk tidak valid.');
    }
    final inventoryId = inventory is String
        ? inventory
        : inventory['_id'] ?? inventory['id'];
    final inventoryName = inventory is Map<String, dynamic>
        ? inventory['name']
        : inventory;
    final unitId = unit is String ? unit : unit['_id'] ?? unit['id'];
    final unitName = unit is Map<String, dynamic> ? unit['name'] : unit;
    final abbreviation = unit is Map<String, dynamic>
        ? unit['abbreviation']
        : '';
    if (inventoryId is! String ||
        inventoryName is! String ||
        unitId is! String ||
        unitName is! String ||
        abbreviation is! String) {
      throw const FormatException('Referensi bahan resep tidak valid.');
    }
    return ProductRecipeModel(
      inventoryId: inventoryId,
      inventoryName: inventoryName,
      quantity: quantity,
      unitId: unitId,
      unitName: unitName,
      unitAbbreviation: abbreviation,
      conversionFactor: conversionFactor,
    );
  }
}
