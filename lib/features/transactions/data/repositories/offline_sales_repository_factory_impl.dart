// ignore_for_file: prefer_initializing_formals

import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/products/data/repositories/offline_cached_catalog_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/shifts/data/repositories/offline_cached_shifts_repository.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/transactions/application/offline_sales_repository_factory.dart';
import 'package:kawula_pos/features/transactions/data/repositories/offline_cached_checkout_repository.dart';
import 'package:kawula_pos/features/transactions/data/repositories/offline_checkout_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

class OfflineSalesRepositoryFactoryImpl
    implements OfflineSalesRepositoryFactory {
  const OfflineSalesRepositoryFactoryImpl({
    required CatalogRepository catalogRepository,
    required CheckoutRepository checkoutRepository,
    required ShiftsRepository shiftsRepository,
    required OfflineMasterDataCache? masterDataCache,
    required OfflineTransactionsDao? offlineTransactionsDao,
  }) : _catalogRepository = catalogRepository,
       _checkoutRepository = checkoutRepository,
       _shiftsRepository = shiftsRepository,
       _masterDataCache = masterDataCache,
       _offlineTransactionsDao = offlineTransactionsDao;

  final CatalogRepository _catalogRepository;
  final CheckoutRepository _checkoutRepository;
  final ShiftsRepository _shiftsRepository;
  final OfflineMasterDataCache? _masterDataCache;
  final OfflineTransactionsDao? _offlineTransactionsDao;

  @override
  ShiftsRepository shiftsRepositoryFor(AuthUser user) {
    final cache = _masterDataCache;
    if (cache == null || !canUseOfflineSales(user.role)) {
      return _shiftsRepository;
    }
    return OfflineCachedShiftsRepository(
      _shiftsRepository,
      cache,
      ownerUserId: user.id,
      role: user.role,
    );
  }

  @override
  OfflineSalesRepositoryScope createScope({
    required AuthUser user,
    required ActiveShift shift,
  }) {
    final scopedCache = _masterDataCache?.forRole(
      role: user.role,
      userId: user.id,
      outletId: shift.outletId,
    );
    if (scopedCache == null) {
      return OfflineSalesRepositoryScope(
        catalogRepository: _catalogRepository,
        checkoutRepository: _checkoutRepository,
        masterDataCache: null,
      );
    }

    final catalogRepository = OfflineCachedCatalogRepository(
      _catalogRepository,
      scopedCache,
      offlineTransactionsDao: _offlineTransactionsDao,
    );
    final cachedCheckoutRepository = OfflineCachedCheckoutRepository(
      _checkoutRepository,
      scopedCache,
    );
    final transactionsDao = _offlineTransactionsDao;
    final checkoutRepository = transactionsDao == null
        ? cachedCheckoutRepository
        : OfflineCheckoutRepository(
            cachedCheckoutRepository,
            scopedCache,
            transactionsDao,
            user: user,
            shift: shift,
          );
    return OfflineSalesRepositoryScope(
      catalogRepository: catalogRepository,
      checkoutRepository: checkoutRepository,
      masterDataCache: scopedCache,
    );
  }
}
