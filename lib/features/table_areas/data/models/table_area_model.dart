import '../../domain/entities/table_area.dart';

class TableAreaModel extends TableArea {
  const TableAreaModel({
    required super.id,
    required super.name,
    required super.outletId,
    required super.outletName,
    required super.description,
    required super.isActive,
  });

  factory TableAreaModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final outletData = json['outlet_id'];
    final outletId = outletData is Map<String, dynamic>
        ? outletData['_id'] ?? outletData['id']
        : outletData;
    final outletName = outletData is Map<String, dynamic>
        ? outletData['name']
        : null;
    if (id is! String || name is! String || outletId is! String) {
      throw const FormatException('Data area meja dari server tidak valid.');
    }
    return TableAreaModel(
      id: id,
      name: name,
      outletId: outletId,
      outletName: outletName is String ? outletName : '',
      description: json['description'] is String
          ? json['description'] as String
          : '',
      isActive: json['is_active'] != false,
    );
  }
}
