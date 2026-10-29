import '../../domain/entities/discount_definition.dart';
import '../../domain/repositories/discounts_repository.dart';
import '../datasources/discounts_remote_data_source.dart';

class DiscountsRepositoryImpl implements DiscountsRepository {
  const DiscountsRepositoryImpl(this._remoteDataSource);

  final DiscountsRemoteDataSource _remoteDataSource;

  @override
  Future<List<DiscountDefinition>> getDiscounts() =>
      _remoteDataSource.getDiscounts();

  @override
  Future<DiscountDefinition> saveDiscount({
    String? discountId,
    required String name,
    required DiscountType type,
    required num value,
    required String description,
    required bool isActive,
  }) => _remoteDataSource.saveDiscount(
    discountId: discountId,
    name: name,
    type: type,
    value: value,
    description: description,
    isActive: isActive,
  );

  @override
  Future<void> deleteDiscount(String discountId) =>
      _remoteDataSource.deleteDiscount(discountId);
}
