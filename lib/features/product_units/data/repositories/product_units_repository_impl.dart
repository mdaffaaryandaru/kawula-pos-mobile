import '../../domain/entities/product_unit.dart';
import '../../domain/repositories/product_units_repository.dart';
import '../datasources/product_units_remote_data_source.dart';

class ProductUnitsRepositoryImpl implements ProductUnitsRepository {
  const ProductUnitsRepositoryImpl(this._remoteDataSource);

  final ProductUnitsRemoteDataSource _remoteDataSource;

  @override
  Future<List<ProductUnit>> getProductUnits() =>
      _remoteDataSource.getProductUnits();

  @override
  Future<ProductUnit> saveProductUnit({
    String? unitId,
    required String name,
    required String abbreviation,
    required String description,
    required bool isActive,
  }) => _remoteDataSource.saveProductUnit(
    unitId: unitId,
    name: name,
    abbreviation: abbreviation,
    description: description,
    isActive: isActive,
  );

  @override
  Future<void> deleteProductUnit(String unitId) =>
      _remoteDataSource.deleteProductUnit(unitId);
}
