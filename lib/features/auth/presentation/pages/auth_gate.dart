// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawula_pos/features/auth/presentation/pages/login_page.dart';
import 'package:kawula_pos/features/auth/presentation/widgets/auth_loading_view.dart';
import 'package:kawula_pos/features/auth/presentation/widgets/auth_session_failure_view.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_navigation_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/cashier_navigation_page.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/features/discounts/domain/repositories/discounts_repository.dart';
import 'package:kawula_pos/features/inventories/domain/repositories/inventory_repository.dart';
import 'package:kawula_pos/features/members/domain/repositories/members_repository.dart';
import 'package:kawula_pos/features/membership_programs/domain/repositories/membership_programs_repository.dart';
import 'package:kawula_pos/features/outlets/domain/repositories/outlets_repository.dart';
import 'package:kawula_pos/features/payment_method/domain/repositories/payment_methods_repository.dart';
import 'package:kawula_pos/features/product_units/domain/repositories/product_units_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/product_management_repository.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/shifts/data/repositories/offline_cached_shifts_repository.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/table_areas/domain/repositories/table_areas_repository.dart';
import 'package:kawula_pos/features/tables/domain/repositories/tables_repository.dart';
import 'package:kawula_pos/features/transactions/data/services/offline_transaction_sync_service.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/variant_groups/domain/repositories/variant_groups_repository.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.shiftsRepository,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.balancesRepository,
    required this.storeSettingsRepository,
    required this.apiBaseUrl,
    required this.userManagementRepository,
    required this.productManagementRepository,
    required this.categoriesRepository,
    required this.variantGroupsRepository,
    this.masterDataCache,
    this.offlineTransactionsDao,
    this.offlineTransactionSyncService,
    this.discountsRepository,
    this.paymentMethodsRepository,
    this.inventoryRepository,
    this.productUnitsRepository,
    this.outletsRepository,
    this.tableAreasRepository,
    this.tablesRepository,
    this.membersRepository,
    this.membershipProgramsRepository,
  });

  final ShiftsRepository shiftsRepository;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final BalancesRepository balancesRepository;
  final StoreSettingsRepository storeSettingsRepository;
  final String apiBaseUrl;
  final UserManagementRepository userManagementRepository;
  final ProductManagementRepository productManagementRepository;
  final CategoriesRepository categoriesRepository;
  final VariantGroupsRepository variantGroupsRepository;
  final OfflineMasterDataCache? masterDataCache;
  final OfflineTransactionsDao? offlineTransactionsDao;
  final OfflineTransactionSyncService? offlineTransactionSyncService;
  final DiscountsRepository? discountsRepository;
  final PaymentMethodsRepository? paymentMethodsRepository;
  final InventoryRepository? inventoryRepository;
  final ProductUnitsRepository? productUnitsRepository;
  final OutletsRepository? outletsRepository;
  final TableAreasRepository? tableAreasRepository;
  final TablesRepository? tablesRepository;
  final MembersRepository? membersRepository;
  final MembershipProgramsRepository? membershipProgramsRepository;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthChecking() => const AuthLoadingView(),
          AuthSubmitting() => const LoginPage(),
          AuthUnauthenticated() => LoginPage(errorMessage: state.errorMessage),
          AuthAuthenticated() when state.user.role == 'Admin' =>
            AdminNavigationPage(
              admin: state.user,
              shiftsRepository: masterDataCache == null
                  ? shiftsRepository
                  : OfflineCachedShiftsRepository(
                      shiftsRepository,
                      masterDataCache!,
                      ownerUserId: state.user.id,
                      role: state.user.role,
                    ),
              masterDataCache: masterDataCache,
              offlineTransactionsDao: offlineTransactionsDao,
              offlineTransactionSyncService: offlineTransactionSyncService,
              catalogRepository: catalogRepository,
              checkoutRepository: checkoutRepository,
              balancesRepository: balancesRepository,
              storeSettingsRepository: storeSettingsRepository,
              apiBaseUrl: apiBaseUrl,
              userManagementRepository: userManagementRepository,
              productManagementRepository: productManagementRepository,
              categoriesRepository: categoriesRepository,
              discountsRepository: discountsRepository,
              paymentMethodsRepository: paymentMethodsRepository,
              variantGroupsRepository: variantGroupsRepository,
              inventoryRepository: inventoryRepository,
              productUnitsRepository: productUnitsRepository,
              outletsRepository: outletsRepository,
              tableAreasRepository: tableAreasRepository,
              tablesRepository: tablesRepository,
              membersRepository: membersRepository,
              membershipProgramsRepository: membershipProgramsRepository,
            ),
          AuthAuthenticated()
              when state.user.role == 'Kasir' && masterDataCache != null =>
            CashierNavigationPage(
              user: state.user,
              offlineMasterDataCache: masterDataCache,
              shiftsRepository: OfflineCachedShiftsRepository(
                shiftsRepository,
                masterDataCache!,
                ownerUserId: state.user.id,
                role: state.user.role,
              ),
              catalogRepository: catalogRepository,
              checkoutRepository: checkoutRepository,
              balancesRepository: balancesRepository,
              offlineTransactionsDao: offlineTransactionsDao,
              offlineTransactionSyncService: offlineTransactionSyncService,
              storeSettingsRepository: storeSettingsRepository,
            ),
          AuthAuthenticated() => CashierNavigationPage(
            user: state.user,
            shiftsRepository: shiftsRepository,
            catalogRepository: catalogRepository,
            checkoutRepository: checkoutRepository,
            balancesRepository: balancesRepository,
            offlineTransactionsDao: offlineTransactionsDao,
            offlineTransactionSyncService: offlineTransactionSyncService,
            storeSettingsRepository: storeSettingsRepository,
          ),
          AuthSessionFailure() => AuthSessionFailureView(
            message: state.message,
          ),
        };
      },
    );
  }
}
