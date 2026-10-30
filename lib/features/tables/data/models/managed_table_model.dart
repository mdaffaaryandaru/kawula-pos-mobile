import '../../domain/entities/managed_table.dart';

class ManagedTableModel extends ManagedTable {
  const ManagedTableModel({
    required super.id,
    required super.name,
    required super.areaId,
    required super.areaName,
    required super.capacity,
    required super.status,
    required super.isActive,
  });

  factory ManagedTableModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final name = json['name'];
    final areaData = json['area_id'];
    final areaId = areaData is Map<String, dynamic>
        ? areaData['_id'] ?? areaData['id']
        : areaData;
    final areaName = areaData is Map<String, dynamic> ? areaData['name'] : null;
    final rawCapacity = json['capacity'];
    final capacity = rawCapacity is num ? rawCapacity.toInt() : null;
    final status = json['status'];
    if (id is! String ||
        name is! String ||
        areaId is! String ||
        capacity == null ||
        status is! String) {
      throw const FormatException('Data meja dari server tidak valid.');
    }
    if (!tableStatuses.contains(status)) {
      throw const FormatException('Status meja dari server tidak valid.');
    }
    return ManagedTableModel(
      id: id,
      name: name,
      areaId: areaId,
      areaName: areaName is String ? areaName : '',
      capacity: capacity,
      status: status,
      isActive: json['is_active'] != false,
    );
  }
}

const tableStatuses = ['available', 'occupied', 'reserved'];
