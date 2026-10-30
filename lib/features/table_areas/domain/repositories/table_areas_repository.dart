import '../entities/table_area.dart';

abstract interface class TableAreasRepository {
  Future<List<TableArea>> getTableAreas();

  Future<TableArea> saveTableArea({
    String? areaId,
    required String name,
    required String outletId,
    required String description,
    required bool isActive,
  });

  Future<void> deleteTableArea(String areaId);
}
