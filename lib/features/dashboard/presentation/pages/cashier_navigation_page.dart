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
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/offline_sales_tab.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_state.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/transactions/data/services/offline_transaction_sync_service.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_transaction_report_page.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';

class CashierNavigationPage extends StatefulWidget {
  const CashierNavigationPage({
    super.key,
    required this.user,
    this.offlineMasterDataCache,
    required this.shiftsRepository,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.balancesRepository,
    this.offlineTransactionsDao,
    this.offlineTransactionSyncService,
    this.storeSettingsRepository,
  });

  final AuthUser user;
  final OfflineMasterDataCache? offlineMasterDataCache;
  final ShiftsRepository shiftsRepository;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final BalancesRepository balancesRepository;
  final OfflineTransactionsDao? offlineTransactionsDao;
  final OfflineTransactionSyncService? offlineTransactionSyncService;
  final StoreSettingsRepository? storeSettingsRepository;

  @override
  State<CashierNavigationPage> createState() => _CashierNavigationPageState();
}

class _CashierNavigationPageState extends State<CashierNavigationPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final ShiftsCubit _shiftsCubit;
  late final List<Widget?> _pages;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _recoveryTimer;
  bool _hasNetworkConnectivity = false;
  bool _isVerifyingServer = false;

  @override
  void initState() {
    super.initState();
    _shiftsCubit = ShiftsCubit(widget.shiftsRepository)..loadActive();
    _pages = List<Widget?>.filled(3, null);
    _pages[0] = _pageAt(0);
    if (widget.user.role == 'Kasir' && widget.offlineMasterDataCache != null) {
      WidgetsBinding.instance.addObserver(this);
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (Object error, StackTrace stackTrace) {
          widget.offlineMasterDataCache?.markOffline();
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
    _recoveryTimer?.cancel();
    _shiftsCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshConnectivity());
    }
  }

  Future<void> _refreshConnectivity() async {
    if (widget.user.role != 'Kasir' || widget.offlineMasterDataCache == null) {
      return;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      await _onConnectivityChanged(results);
    } on Exception {
      widget.offlineMasterDataCache?.markOffline();
      if (mounted) setState(() {});
    }
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    _hasNetworkConnectivity = results.any(
      (result) => result != ConnectivityResult.none,
    );
    final cache = widget.offlineMasterDataCache;
    if (!_hasNetworkConnectivity) {
      cache?.markOffline();
      if (mounted) setState(() {});
      return;
    }

    final shiftState = _shiftsCubit.state;
    final hasOfflineSnapshot =
        shiftState is ShiftsActive && shiftState.shift.isOfflineSnapshot;
    if (cache?.isOfflineKnown == true ||
        widget.user.isOfflineSession ||
        hasOfflineSnapshot) {
      cache?.markChecking();
      if (mounted) setState(() {});
      await _verifyServerSession();
    }
  }

  Future<void> _retryRecoveryWhenOffline() async {
    if (!_hasNetworkConnectivity ||
        widget.offlineMasterDataCache?.isOfflineKnown != true) {
      return;
    }
    await _refreshConnectivity();
  }

  Future<void> _verifyServerSession() async {
    if (_isVerifyingServer || !mounted) return;
    _isVerifyingServer = true;
    final cache = widget.offlineMasterDataCache;
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
      1 => OfflineSalesTab(
        admin: widget.user,
        catalogRepository: widget.catalogRepository,
        checkoutRepository: widget.checkoutRepository,
        offlineMasterDataCache: widget.offlineMasterDataCache,
        offlineTransactionsDao: widget.offlineTransactionsDao,
        offlineTransactionSyncService: widget.offlineTransactionSyncService,
        storeSettingsRepository: widget.storeSettingsRepository,
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
