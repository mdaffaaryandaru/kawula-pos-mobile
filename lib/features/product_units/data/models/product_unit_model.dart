import '../../domain/entities/product_unit.dart';

class ProductUnitModel extends ProductUnit {
  const ProductUnitModel({
    required super.id,
    required super.name,
    required super.abbreviation,
    super.isActive,
    super.description,
  });

  factory ProductUnitModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    if (id is! String || json['name'] is! String) {
      throw const FormatException('Data satuan inventori tidak valid.');
    }
    final abbreviation = json['abbreviation'];
    if (abbreviation is! String || abbreviation.isEmpty) {
      throw const FormatException('Singkatan satuan inventori tidak valid.');
    }
    return ProductUnitModel(
      id: id,
      name: json['name'] as String,
      abbreviation: abbreviation,
      isActive: json['is_active'] != false,
      description: json['description'] is String
          ? json['description'] as String
          : '',
    );
  }
}
