import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../balances/domain/repositories/balances_repository.dart';
import '../../../categories/domain/repositories/categories_repository.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../../products/domain/repositories/product_management_repository.dart';
import '../../../products/presentation/bloc/cart_cubit.dart';
import '../../../products/presentation/bloc/catalog_cubit.dart';
import '../../../products/presentation/pages/catalog_page.dart';
import '../../../shifts/domain/repositories/shifts_repository.dart';
import '../../../shifts/presentation/bloc/shifts_cubit.dart';
import '../../../shifts/presentation/bloc/shifts_state.dart';
import '../../../shifts/presentation/pages/shift_status_view.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../transactions/presentation/pages/admin_transaction_report_page.dart';
import '../../../users/domain/repositories/user_management_repository.dart';
import '../../../variant_groups/domain/repositories/variant_groups_repository.dart';
import '../../../store_settings/domain/repositories/store_settings_repository.dart';
import 'admin_dashboard_page.dart';
import 'admin_management_page.dart';

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

  @override
  State<AdminNavigationPage> createState() => _AdminNavigationPageState();
}

class _AdminNavigationPageState extends State<AdminNavigationPage> {
  int _selectedIndex = 0;
  late final List<Widget?> _pages;

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
    setState(() {
      _selectedIndex = index;
      _pages[index] ??= _pageAt(index);
    });
  }

  Widget _pageAt(int index) {
    return switch (index) {
      0 => AdminDashboardPage(
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
      1 => _CashierTab(
        admin: widget.admin,
        catalogRepository: widget.catalogRepository,
        checkoutRepository: widget.checkoutRepository,
        onManageShift: () => _selectDestination(2),
      ),
      2 => AdminManagementPage(
        admin: widget.admin,
        apiBaseUrl: widget.apiBaseUrl,
        userManagementRepository: widget.userManagementRepository,
        productManagementRepository: widget.productManagementRepository,
        categoriesRepository: widget.categoriesRepository,
        balancesRepository: widget.balancesRepository,
        storeSettingsRepository: widget.storeSettingsRepository,
        checkoutRepository: widget.checkoutRepository,
        shiftsRepository: widget.shiftsRepository,
        variantGroupsRepository: widget.variantGroupsRepository,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _CashierTab extends StatelessWidget {
  const _CashierTab({
    required this.admin,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.onManageShift,
  });

  final AuthUser admin;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final VoidCallback onManageShift;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftsCubit, ShiftsState>(
      builder: (context, state) => switch (state) {
        ShiftsLoading() => const Scaffold(
          appBar: _CashierAppBar(),
          body: Center(child: CircularProgressIndicator()),
        ),
        ShiftsNeedsOpening() => Scaffold(
          appBar: const _CashierAppBar(),
          body: ShiftStatusView(
            user: admin,
            cashAvailability: state.cashAvailability,
            errorMessage: state.errorMessage,
          ),
        ),
        ShiftsOpening() => Scaffold(
          appBar: const _CashierAppBar(),
          body: ShiftStatusView(
            user: admin,
            cashAvailability: state.cashAvailability,
            isOpening: true,
          ),
        ),
        ShiftsActive() => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => CatalogCubit(catalogRepository)..load(),
            ),
            BlocProvider(create: (_) => CartCubit()),
          ],
          child: CatalogPage(
            user: admin,
            checkoutRepository: checkoutRepository,
            outletId: state.shift.outletId,
            activeShift: state.shift,
            onManageShift: onManageShift,
          ),
        ),
        ShiftsClosing() => Scaffold(
          appBar: const _CashierAppBar(),
          body: ShiftStatusView(
            user: admin,
            shift: state.shift,
            isClosing: true,
          ),
        ),
        ShiftsClosed() => Scaffold(
          appBar: const _CashierAppBar(),
          body: ShiftStatusView(
            user: admin,
            shift: state.shift,
            isClosed: true,
          ),
        ),
        ShiftsFailure() => Scaffold(
          appBar: const _CashierAppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Shift belum dapat diperiksa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: context.read<ShiftsCubit>().loadActive,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      },
    );
  }
}

class _CashierAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CashierAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        const Text('Kasir'),
      ],
    ),
  );
}
