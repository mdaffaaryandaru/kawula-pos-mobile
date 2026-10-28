import '../../domain/entities/variant_group_definition.dart';
import '../../domain/repositories/variant_groups_repository.dart';
import '../datasources/variant_groups_remote_data_source.dart';

class VariantGroupsRepositoryImpl implements VariantGroupsRepository {
  const VariantGroupsRepositoryImpl(this._remoteDataSource);

  final VariantGroupsRemoteDataSource _remoteDataSource;

  @override
  Future<List<VariantGroupDefinition>> getVariantGroupDefinitions() =>
      _remoteDataSource.getVariantGroupDefinitions();

  @override
  Future<VariantRecipeReferences> getVariantRecipeReferences() =>
      _remoteDataSource.getVariantRecipeReferences();

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
