import '../../domain/entities/managed_category.dart';

class ManagedCategoryModel extends ManagedCategory {
  const ManagedCategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.isActive,
  });

  factory ManagedCategoryModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final description = json['description'];
    if (id is! String || name is! String) {
      throw const FormatException('Data kategori dari server tidak valid.');
    }
    return ManagedCategoryModel(
      id: id,
      name: name,
      description: description is String ? description : '',
      isActive: json['is_active'] != false,
    );
  }
}
