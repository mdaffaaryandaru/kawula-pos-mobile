import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_management_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/offline_sales_tab.dart';
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
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_state.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/table_areas/domain/repositories/table_areas_repository.dart';
import 'package:kawula_pos/features/tables/domain/repositories/tables_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_transaction_report_page.dart';
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/variant_groups/domain/repositories/variant_groups_repository.dart';
import 'package:kawula_pos/features/transactions/data/services/offline_transaction_sync_service.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

class AdminNavigationPage extends StatefulWidget {
  const AdminNavigationPage({
    super.key,
    required this.admin,
    required this.shiftsRepository,
    this.masterDataCache,
    this.offlineTransactionsDao,
    this.offlineTransactionSyncService,
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
  final OfflineMasterDataCache? masterDataCache;
  final OfflineTransactionsDao? offlineTransactionsDao;
  final OfflineTransactionSyncService? offlineTransactionSyncService;
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

class _AdminNavigationPageState extends State<AdminNavigationPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late ShiftsCubit _shiftsCubit;
  late final List<Widget?> _pages;
  final _dashboardKey = GlobalKey<AdminDashboardPageState>();
  GlobalKey<CatalogPageState> _catalogPageKey = GlobalKey<CatalogPageState>();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<ShiftsState>? _shiftsSubscription;
  Timer? _recoveryTimer;
  bool _isVerifyingServer = false;
  String? _activeOutletId;

  @override
  void initState() {
    super.initState();
    _shiftsCubit = ShiftsCubit(widget.shiftsRepository)..loadActive();
    _listenToShifts(_shiftsCubit);
    _pages = List<Widget?>.filled(3, null);
    _pages[0] = _pageAt(0);
    if (canUseOfflineSales(widget.admin.role) &&
        widget.masterDataCache != null) {
      WidgetsBinding.instance.addObserver(this);
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (Object error, StackTrace stackTrace) {
          widget.masterDataCache?.markOffline();
          if (mounted) setState(() {});
        },
      );
      unawaited(_refreshConnectivity());
      _recoveryTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _retryRecoveryWhenOffline(),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _shiftsSubscription?.cancel();
    _recoveryTimer?.cancel();
    _shiftsCubit.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdminNavigationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldAdmin = oldWidget.admin;
    final currentAdmin = widget.admin;
    final sameSalesIdentity =
        oldAdmin.id == currentAdmin.id && oldAdmin.role == currentAdmin.role;
    if (sameSalesIdentity) {
      for (var index = 0; index < _pages.length; index++) {
        if (_pages[index] != null) _pages[index] = _pageAt(index);
      }
      return;
    }

    final previousShiftsCubit = _shiftsCubit;
    _shiftsCubit = ShiftsCubit(widget.shiftsRepository)..loadActive();
    _shiftsSubscription?.cancel();
    _listenToShifts(_shiftsCubit);
    _activeOutletId = null;
    _catalogPageKey = GlobalKey<CatalogPageState>();
    for (var index = 0; index < _pages.length; index++) {
      _pages[index] = index == _selectedIndex ? _pageAt(index) : null;
    }
    unawaited(previousShiftsCubit.close());
  }

  void _listenToShifts(ShiftsCubit shiftsCubit) {
    _shiftsSubscription = shiftsCubit.stream.listen((state) {
      final outletId = state is ShiftsActive ? state.shift.outletId : null;
      if (outletId == _activeOutletId) return;
      final hadActiveOutlet = _activeOutletId != null;
      _activeOutletId = outletId;
      if (!hadActiveOutlet || !mounted) return;

      _catalogPageKey = GlobalKey<CatalogPageState>();
      if (_pages[1] != null) {
        setState(() => _pages[1] = _pageAt(1));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshConnectivity());
  }

  Future<void> _refreshConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _onConnectivityChanged(results);
    } on Exception {
      widget.masterDataCache?.markOffline();
      if (mounted) setState(() {});
    }
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    final cache = widget.masterDataCache;
    if (!isConnected) {
      cache?.markOffline();
      if (mounted) setState(() {});
      return;
    }
    if (cache?.isOfflineKnown == true || widget.admin.isOfflineSession) {
      cache?.markChecking();
      if (mounted) setState(() {});
      await _verifyServerSession();
    }
  }

  Future<void> _retryRecoveryWhenOffline() async {
    if (widget.masterDataCache?.isOfflineKnown == true) {
      await _refreshConnectivity();
    }
  }

  Future<void> _verifyServerSession() async {
    if (_isVerifyingServer || !mounted) return;
    _isVerifyingServer = true;
    final cache = widget.masterDataCache;
    try {
      final verified = await context
          .read<AuthCubit>()
          .verifyOfflineSalesSession();
      if (!mounted) return;
      if (verified) {
        await _shiftsCubit.refreshActive();
      } else if (cache?.networkStatus == OfflineNetworkStatus.checking) {
        cache?.markOffline();
      }
    } on Exception {
      if (cache?.networkStatus == OfflineNetworkStatus.checking) {
        cache?.markOffline();
      }
    } finally {
      _isVerifyingServer = false;
      if (mounted) setState(() {});
    }
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
      0 => _onlineOnly(
        AdminDashboardPage(
          key: _dashboardKey,
          admin: widget.admin,
          checkoutRepository: widget.checkoutRepository,
          onOpenCashier: () => _selectDestination(1),
          onOpenReport: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _onlineOnly(
                  AdminTransactionReportPage(
                    checkoutRepository: widget.checkoutRepository,
                    balancesRepository: widget.balancesRepository,
                  ),
                ),
              ),
            );
          },
          onOpenManagement: () => _selectDestination(2),
        ),
      ),
      1 => OfflineSalesTab(
        key: ValueKey<(String, String)>((widget.admin.id, widget.admin.role)),
        admin: widget.admin,
        catalogRepository: widget.catalogRepository,
        checkoutRepository: widget.checkoutRepository,
        offlineMasterDataCache: widget.masterDataCache,
        offlineTransactionsDao: widget.offlineTransactionsDao,
        offlineTransactionSyncService: widget.offlineTransactionSyncService,
        storeSettingsRepository: widget.storeSettingsRepository,
        catalogPageKey: _catalogPageKey,
      ),
      2 => _onlineOnly(
        AdminManagementPage(
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
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _onlineOnly(Widget child) =>
      _OnlineOnlyAdminPage(cache: widget.masterDataCache, child: child);
}

class _OnlineOnlyAdminPage extends StatelessWidget {
  const _OnlineOnlyAdminPage({required this.cache, required this.child});

  final OfflineMasterDataCache? cache;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final statusListenable = cache?.networkStatusListenable;
    if (statusListenable == null) return child;
    return ValueListenableBuilder<OfflineNetworkStatus>(
      valueListenable: statusListenable,
      builder: (context, status, _) => status != OfflineNetworkStatus.online
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        status == OfflineNetworkStatus.checking
                            ? 'Memverifikasi koneksi dan sesi...'
                            : 'Halaman ini memerlukan koneksi internet.',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : child,
    );
  }
}
