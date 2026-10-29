import '../../domain/entities/discount_definition.dart';

class DiscountModel extends DiscountDefinition {
  const DiscountModel({
    required super.id,
    required super.name,
    required super.type,
    required super.value,
    required super.description,
    required super.isActive,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final type = json['type'];
    final value = json['value'];
    final description = json['description'];
    if (id is! String || name is! String || type is! String || value is! num) {
      throw const FormatException('Data diskon dari server tidak valid.');
    }
    return DiscountModel(
      id: id,
      name: name,
      type: DiscountType.fromApiValue(type),
      value: value,
      description: description is String ? description : '',
      isActive: json['is_active'] != false,
    );
  }
}
