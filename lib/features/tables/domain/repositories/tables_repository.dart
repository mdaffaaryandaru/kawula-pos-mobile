import '../entities/managed_table.dart';

abstract interface class TablesRepository {
  Future<List<ManagedTable>> getTables();

  Future<ManagedTable> saveTable({
    String? tableId,
    required String name,
    required String areaId,
    required int capacity,
    required String status,
    required bool isActive,
  });

  Future<void> deleteTable(String tableId);
}
