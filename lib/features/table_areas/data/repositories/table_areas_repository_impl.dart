import '../../domain/entities/table_area.dart';
import '../../domain/repositories/table_areas_repository.dart';
import '../datasources/table_areas_remote_data_source.dart';

class TableAreasRepositoryImpl implements TableAreasRepository {
  const TableAreasRepositoryImpl(this._remoteDataSource);

  final TableAreasRemoteDataSource _remoteDataSource;

  @override
  Future<List<TableArea>> getTableAreas() => _remoteDataSource.getTableAreas();

  @override
  Future<TableArea> saveTableArea({
    String? areaId,
    required String name,
    required String outletId,
    required String description,
    required bool isActive,
  }) {
    return _remoteDataSource.saveTableArea(
      areaId: areaId,
      name: name,
      outletId: outletId,
      description: description,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteTableArea(String areaId) =>
      _remoteDataSource.deleteTableArea(areaId);
}
