import '../entities/discount_definition.dart';

abstract interface class DiscountsRepository {
  Future<List<DiscountDefinition>> getDiscounts();

  Future<DiscountDefinition> saveDiscount({
    String? discountId,
    required String name,
    required DiscountType type,
    required num value,
    required String description,
    required bool isActive,
  });

  Future<void> deleteDiscount(String discountId);
}
