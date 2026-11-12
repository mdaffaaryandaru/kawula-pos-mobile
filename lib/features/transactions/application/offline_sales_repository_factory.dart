import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';

class OfflineSalesRepositoryScope {
  const OfflineSalesRepositoryScope({
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.masterDataCache,
  });

  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final OfflineMasterDataCache? masterDataCache;
}

abstract interface class OfflineSalesRepositoryFactory {
  ShiftsRepository shiftsRepositoryFor(AuthUser user);

  OfflineSalesRepositoryScope createScope({
    required AuthUser user,
    required ActiveShift shift,
  });
}
