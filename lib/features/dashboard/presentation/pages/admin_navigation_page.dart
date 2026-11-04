// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_management_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/cashier_tab.dart';
import 'package:kawula_pos/features/discounts/domain/repositories/discounts_repository.dart';
import 'package:kawula_pos/features/inventories/domain/repositories/inventory_repository.dart';
import 'package:kawula_pos/features/members/domain/repositories/members_repository.dart';
import 'package:kawula_pos/features/membership_programs/domain/repositories/membership_programs_repository.dart';
import 'package:kawula_pos/features/outlets/domain/repositories/outlets_repository.dart';
import 'package:kawula_pos/features/payment_method/domain/repositories/payment_methods_repository.dart';
import 'package:kawula_pos/features/product_units/domain/repositories/product_units_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/product_management_repository.dart';
import 'package:kawula_pos/features/products/presentation/pages/catalog_page.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/table_areas/domain/repositories/table_areas_repository.dart';
import 'package:kawula_pos/features/tables/domain/repositories/tables_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_transaction_report_page.dart';
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/variant_groups/domain/repositories/variant_groups_repository.dart';

class AdminNavigationPage extends StatefulWidget {
  const AdminNavigationPage({
    super.key,
    required this.admin,
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
    this.membershipProgramsRepository,
  });

  final AuthUser admin;
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
  final MembershipProgramsRepository? membershipProgramsRepository;

  @override
  State<AdminNavigationPage> createState() => _AdminNavigationPageState();
}

class _AdminNavigationPageState extends State<AdminNavigationPage> {
  int _selectedIndex = 0;
  late final List<Widget?> _pages;
  final _dashboardKey = GlobalKey<AdminDashboardPageState>();
  final _catalogPageKey = GlobalKey<CatalogPageState>();

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(3, null);
    _pages[0] = _pageAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShiftsCubit(widget.shiftsRepository)..loadActive(),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(
            _pages.length,
            (index) => _pages[index] ?? const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectDestination,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Kasir',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'Manajemen',
            ),
          ],
        ),
      ),
    );
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
      _pages[index] ??= _pageAt(index);
    });
    if (index == 0) _dashboardKey.currentState?.refresh();
    if (index == 1) _catalogPageKey.currentState?.refreshCatalog();
  }

  Widget _pageAt(int index) {
    return switch (index) {
      0 => AdminDashboardPage(
        key: _dashboardKey,
        admin: widget.admin,
        checkoutRepository: widget.checkoutRepository,
        onOpenCashier: () => _selectDestination(1),
        onOpenReport: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AdminTransactionReportPage(
                checkoutRepository: widget.checkoutRepository,
                balancesRepository: widget.balancesRepository,
              ),
            ),
          );
        },
        onOpenManagement: () => _selectDestination(2),
      ),
      1 => CashierTab(
        admin: widget.admin,
        catalogRepository: widget.catalogRepository,
        checkoutRepository: widget.checkoutRepository,
        catalogPageKey: _catalogPageKey,
      ),
      2 => AdminManagementPage(
        admin: widget.admin,
        apiBaseUrl: widget.apiBaseUrl,
        catalogRepository: widget.catalogRepository,
        userManagementRepository: widget.userManagementRepository,
        productManagementRepository: widget.productManagementRepository,
        categoriesRepository: widget.categoriesRepository,
        balancesRepository: widget.balancesRepository,
        storeSettingsRepository: widget.storeSettingsRepository,
        checkoutRepository: widget.checkoutRepository,
        shiftsRepository: widget.shiftsRepository,
        variantGroupsRepository: widget.variantGroupsRepository,
        discountsRepository: widget.discountsRepository,
        paymentMethodsRepository: widget.paymentMethodsRepository,
        inventoryRepository: widget.inventoryRepository,
        productUnitsRepository: widget.productUnitsRepository,
        outletsRepository: widget.outletsRepository,
        tableAreasRepository: widget.tableAreasRepository,
        tablesRepository: widget.tablesRepository,
        membersRepository: widget.membersRepository,
        membershipProgramsRepository: widget.membershipProgramsRepository,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
