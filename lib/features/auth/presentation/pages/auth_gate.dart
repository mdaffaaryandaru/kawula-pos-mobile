import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';
import '../widgets/auth_loading_view.dart';
import '../widgets/auth_session_failure_view.dart';
import '../../../balances/domain/repositories/balances_repository.dart';
import '../../../categories/domain/repositories/categories_repository.dart';
import '../../../discounts/domain/repositories/discounts_repository.dart';
import '../../../shifts/domain/repositories/shifts_repository.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../users/domain/repositories/user_management_repository.dart';
import '../../../products/domain/repositories/product_management_repository.dart';
import '../../../dashboard/presentation/pages/admin_navigation_page.dart';
import '../../../dashboard/presentation/pages/cashier_navigation_page.dart';
import '../../../variant_groups/domain/repositories/variant_groups_repository.dart';
import '../../../store_settings/domain/repositories/store_settings_repository.dart';
import '../../../inventories/domain/repositories/inventory_repository.dart';
import '../../../product_units/domain/repositories/product_units_repository.dart';
import '../../../payment_method/domain/repositories/payment_methods_repository.dart';
import '../../../outlets/domain/repositories/outlets_repository.dart';
import '../../../table_areas/domain/repositories/table_areas_repository.dart';
import '../../../tables/domain/repositories/tables_repository.dart';
import '../../../members/domain/repositories/members_repository.dart';

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
    this.discountsRepository,
    this.paymentMethodsRepository,
    this.inventoryRepository,
    this.productUnitsRepository,
    this.outletsRepository,
    this.tableAreasRepository,
    this.tablesRepository,
    this.membersRepository,
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
  final DiscountsRepository? discountsRepository;
  final PaymentMethodsRepository? paymentMethodsRepository;
  final InventoryRepository? inventoryRepository;
  final ProductUnitsRepository? productUnitsRepository;
  final OutletsRepository? outletsRepository;
  final TableAreasRepository? tableAreasRepository;
  final TablesRepository? tablesRepository;
  final MembersRepository? membersRepository;

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
              shiftsRepository: shiftsRepository,
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
            ),
          AuthAuthenticated() => CashierNavigationPage(
            user: state.user,
            shiftsRepository: shiftsRepository,
            catalogRepository: catalogRepository,
            checkoutRepository: checkoutRepository,
            balancesRepository: balancesRepository,
          ),
          AuthSessionFailure() => AuthSessionFailureView(
            message: state.message,
          ),
        };
      },
    );
  }
}
