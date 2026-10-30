import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../balances/domain/repositories/balances_repository.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../../shifts/domain/repositories/shifts_repository.dart';
import '../../../shifts/presentation/bloc/shifts_cubit.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../transactions/presentation/pages/admin_transaction_report_page.dart';
import '../widgets/cashier_tab.dart';
import 'admin_dashboard_page.dart';

class CashierNavigationPage extends StatefulWidget {
  const CashierNavigationPage({
    super.key,
    required this.user,
    required this.shiftsRepository,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.balancesRepository,
  });

  final AuthUser user;
  final ShiftsRepository shiftsRepository;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final BalancesRepository balancesRepository;

  @override
  State<CashierNavigationPage> createState() => _CashierNavigationPageState();
}

class _CashierNavigationPageState extends State<CashierNavigationPage> {
  int _selectedIndex = 0;
  late final ShiftsCubit _shiftsCubit;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();
    _shiftsCubit = ShiftsCubit(widget.shiftsRepository)..loadActive();
    _pages = List<Widget?>.filled(3, null);
    _pages[0] = _pageAt(0);
  }

  @override
  void dispose() {
    _shiftsCubit.close();
    super.dispose();
  }

  Widget _pageAt(int index) {
    return switch (index) {
      0 => AdminDashboardPage(
        admin: widget.user,
        checkoutRepository: widget.checkoutRepository,
        onOpenCashier: () => _selectDestination(1),
        onOpenReport: () => _selectDestination(2),
        onOpenManagement: () => _selectDestination(1),
        isCashier: true,
      ),
      1 => CashierTab(
        admin: widget.user,
        catalogRepository: widget.catalogRepository,
        checkoutRepository: widget.checkoutRepository,
      ),
      2 => AdminTransactionReportPage(
        checkoutRepository: widget.checkoutRepository,
        balancesRepository: widget.balancesRepository,
        canRecordExpenses: false,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _shiftsCubit,
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
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Laporan',
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
}
