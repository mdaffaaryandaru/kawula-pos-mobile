import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/dashboard/application/admin_dependencies.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_management_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/offline_sales_tab.dart';
import 'package:kawula_pos/features/offline/domain/services/offline_network_status_controller.dart';
import 'package:kawula_pos/features/products/presentation/pages/catalog_page.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_state.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/auto_close_settings_provider.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/offline/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_transaction_report_page.dart';
import 'package:kawula_pos/features/offline/application/offline_sales_repository_factory.dart';
import 'package:kawula_pos/features/offline/domain/policies/offline_sales_policy.dart';
import 'package:kawula_pos/features/offline/domain/services/offline_transaction_sync.dart';

class AdminNavigationPage extends StatefulWidget {
  const AdminNavigationPage({
    super.key,
    required this.admin,
    required this.adminDependencies,
    required this.shiftsRepository,
    this.offlineNetworkStatusController,
    this.offlineTransactionSyncService,
    required this.checkoutRepository,
    required this.offlineTransactionQueueRepository,
    required this.offlineSalesRepositoryFactory,
    required this.balancesRepository,
    required this.autoCloseSettingsProvider,
  });

  final AuthUser admin;
  final AdminDependencies adminDependencies;
  final ShiftsRepository shiftsRepository;
  final OfflineNetworkStatusController? offlineNetworkStatusController;
  final OfflineTransactionSync? offlineTransactionSyncService;
  final CheckoutRepository checkoutRepository;
  final OfflineTransactionQueueRepository offlineTransactionQueueRepository;
  final OfflineSalesRepositoryFactory offlineSalesRepositoryFactory;
  final BalancesRepository balancesRepository;
  final AutoCloseSettingsProvider autoCloseSettingsProvider;

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
        widget.offlineNetworkStatusController != null) {
      WidgetsBinding.instance.addObserver(this);
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (Object error, StackTrace stackTrace) {
          widget.offlineNetworkStatusController?.markOffline();
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
      widget.offlineNetworkStatusController?.markOffline();
      if (mounted) setState(() {});
    }
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    final networkStatus = widget.offlineNetworkStatusController;
    if (!isConnected) {
      networkStatus?.markOffline();
      if (mounted) setState(() {});
      return;
    }
    if (networkStatus?.status == OfflineNetworkStatus.offline ||
        widget.admin.isOfflineSession) {
      networkStatus?.markChecking();
      if (mounted) setState(() {});
      await _verifyServerSession();
    }
  }

  Future<void> _retryRecoveryWhenOffline() async {
    if (widget.offlineNetworkStatusController?.status ==
        OfflineNetworkStatus.offline) {
      await _refreshConnectivity();
    }
  }

  Future<void> _verifyServerSession() async {
    if (_isVerifyingServer || !mounted) return;
    _isVerifyingServer = true;
    final networkStatus = widget.offlineNetworkStatusController;
    try {
      final verified = await context
          .read<AuthCubit>()
          .verifyOfflineSalesSession();
      if (!mounted) return;
      if (verified) {
        await _shiftsCubit.refreshActive();
      } else if (networkStatus?.status == OfflineNetworkStatus.checking) {
        networkStatus?.markOffline();
      }
    } on Exception {
      if (networkStatus?.status == OfflineNetworkStatus.checking) {
        networkStatus?.markOffline();
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
        offlineSalesRepositoryFactory: widget.offlineSalesRepositoryFactory,
        offlineTransactionQueueRepository:
            widget.offlineTransactionQueueRepository,
        offlineTransactionReconciliation:
            widget.adminDependencies.offlineTransactionReconciliation,
        offlineNetworkStatusController: widget.offlineNetworkStatusController,
        offlineTransactionSyncService: widget.offlineTransactionSyncService,
        autoCloseSettingsProvider: widget.autoCloseSettingsProvider,
        catalogPageKey: _catalogPageKey,
      ),
      2 => _onlineOnly(
        AdminManagementPage(
          admin: widget.admin,
          apiBaseUrl: widget.adminDependencies.apiBaseUrl,
          catalogRepository: widget.adminDependencies.catalogRepository,
          userManagementRepository:
              widget.adminDependencies.userManagementRepository,
          productManagementRepository:
              widget.adminDependencies.productManagementRepository,
          categoriesRepository: widget.adminDependencies.categoriesRepository,
          balancesRepository: widget.balancesRepository,
          storeSettingsRepository:
              widget.adminDependencies.storeSettingsRepository,
          checkoutRepository: widget.checkoutRepository,
          shiftsRepository: widget.shiftsRepository,
          variantGroupsRepository:
              widget.adminDependencies.variantGroupsRepository,
          discountsRepository: widget.adminDependencies.discountsRepository,
          paymentMethodsRepository:
              widget.adminDependencies.paymentMethodsRepository,
          inventoryRepository: widget.adminDependencies.inventoryRepository,
          productUnitsRepository:
              widget.adminDependencies.productUnitsRepository,
          outletsRepository: widget.adminDependencies.outletsRepository,
          tableAreasRepository: widget.adminDependencies.tableAreasRepository,
          tablesRepository: widget.adminDependencies.tablesRepository,
          membersRepository: widget.adminDependencies.membersRepository,
          membershipProgramsRepository:
              widget.adminDependencies.membershipProgramsRepository,
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _onlineOnly(Widget child) => _OnlineOnlyAdminPage(
    statusController: widget.offlineNetworkStatusController,
    child: child,
  );
}

class _OnlineOnlyAdminPage extends StatelessWidget {
  const _OnlineOnlyAdminPage({
    required this.statusController,
    required this.child,
  });

  final OfflineNetworkStatusController? statusController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = statusController;
    if (controller == null) return child;
    return StreamBuilder<OfflineNetworkStatus>(
      stream: controller.statusChanges,
      initialData: controller.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? controller.status;
        return status != OfflineNetworkStatus.online
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
            : child;
      },
    );
  }
}
