import '../../domain/entities/managed_table.dart';
import '../../domain/repositories/tables_repository.dart';
import '../datasources/tables_remote_data_source.dart';

class TablesRepositoryImpl implements TablesRepository {
  const TablesRepositoryImpl(this._remoteDataSource);

  final TablesRemoteDataSource _remoteDataSource;

  @override
  Future<List<ManagedTable>> getTables() => _remoteDataSource.getTables();

  @override
  Future<ManagedTable> saveTable({
    String? tableId,
    required String name,
    required String areaId,
    required int capacity,
    required String status,
    required bool isActive,
  }) {
    return _remoteDataSource.saveTable(
      tableId: tableId,
      name: name,
      areaId: areaId,
      capacity: capacity,
      status: status,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteTable(String tableId) =>
      _remoteDataSource.deleteTable(tableId);
}
