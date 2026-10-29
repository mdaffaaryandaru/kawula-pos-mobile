import '../../domain/entities/variant_group_definition.dart';
import '../../domain/repositories/variant_groups_repository.dart';
import '../../../product_units/domain/repositories/product_units_repository.dart';
import '../datasources/variant_groups_remote_data_source.dart';

class VariantGroupsRepositoryImpl implements VariantGroupsRepository {
  const VariantGroupsRepositoryImpl(
    this._remoteDataSource,
    this._productUnitsRepository,
  );

  final VariantGroupsRemoteDataSource _remoteDataSource;
  final ProductUnitsRepository _productUnitsRepository;

  @override
  Future<List<VariantGroupDefinition>> getVariantGroupDefinitions() =>
      _remoteDataSource.getVariantGroupDefinitions();

  @override
  Future<VariantRecipeReferences> getVariantRecipeReferences() async {
    final inventoriesFuture = _remoteDataSource
        .getVariantRecipeInventoryReferences();
    final unitsFuture = _productUnitsRepository.getProductUnits();
    final inventories = await inventoriesFuture;
    final productUnits = await unitsFuture;
    final units = productUnits
        .map(
          (unit) => VariantRecipeReference(id: unit.id, name: unit.name),
        )
        .toList(growable: false);
    return VariantRecipeReferences(inventories: inventories, units: units);
  }

  @override
  Future<VariantGroupDefinition> saveVariantGroup({
    String? groupId,
    required String name,
    required bool isRequired,
    required int minSelection,
    required int maxSelection,
    required List<VariantOptionDefinition> options,
  }) => _remoteDataSource.saveVariantGroup(
    groupId: groupId,
    name: name,
    isRequired: isRequired,
    minSelection: minSelection,
    maxSelection: maxSelection,
    options: options,
  );

  @override
  Future<void> deleteVariantGroup(String groupId) =>
      _remoteDataSource.deleteVariantGroup(groupId);
}
