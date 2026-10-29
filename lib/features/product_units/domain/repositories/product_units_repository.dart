import '../entities/product_unit.dart';

abstract interface class ProductUnitsRepository {
  Future<List<ProductUnit>> getProductUnits();

  Future<ProductUnit> saveProductUnit({
    String? unitId,
    required String name,
    required String abbreviation,
    required String description,
    required bool isActive,
  });

  Future<void> deleteProductUnit(String unitId);
}
