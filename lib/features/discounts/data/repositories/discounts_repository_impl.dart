// Project imports:
import 'package:kawula_pos/features/discounts/data/datasources/discounts_remote_data_source.dart';
import 'package:kawula_pos/features/discounts/domain/entities/discount_definition.dart';
import 'package:kawula_pos/features/discounts/domain/repositories/discounts_repository.dart';

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
