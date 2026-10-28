import '../entities/variant_group_definition.dart';

abstract interface class VariantGroupsRepository {
  Future<List<VariantGroupDefinition>> getVariantGroupDefinitions();

  Future<VariantRecipeReferences> getVariantRecipeReferences();

  Future<VariantGroupDefinition> saveVariantGroup({
    String? groupId,
    required String name,
    required bool isRequired,
    required int minSelection,
    required int maxSelection,
    required List<VariantOptionDefinition> options,
  });

  Future<void> deleteVariantGroup(String groupId);
}
