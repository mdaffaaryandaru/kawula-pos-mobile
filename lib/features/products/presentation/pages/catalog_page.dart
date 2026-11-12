import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/products/presentation/bloc/catalog_cubit.dart';
import 'package:kawula_pos/features/products/presentation/bloc/catalog_state.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_cart_sheet.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_variant_dialog.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_cart_summary.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_offline_status_widgets.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_open_bills_panel.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_product_browser.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_shift_widgets.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/auto_close_shift_schedule.dart';
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/auto_close_settings_provider.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/features/transactions/domain/services/offline_transaction_sync.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/offline_transaction_queue_page.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.user,
    required this.checkoutRepository,
    required this.offlineTransactionQueueRepository,
    required this.outletId,
    required this.activeShift,
    required this.onManageShift,
    this.onOpenOfflineReconciliation,
    this.offlineTransactionSyncService,
    required this.autoCloseSettingsProvider,
    this.offlineMasterDataCache,
  });

  final AuthUser user;
  final CheckoutRepository checkoutRepository;
  final OfflineTransactionQueueRepository offlineTransactionQueueRepository;
  final String? outletId;
  final ActiveShift activeShift;
  final VoidCallback onManageShift;
  final VoidCallback? onOpenOfflineReconciliation;
  final OfflineTransactionSync? offlineTransactionSyncService;
  final AutoCloseSettingsProvider autoCloseSettingsProvider;
  final OfflineMasterDataCache? offlineMasterDataCache;

  @override
  State<CatalogPage> createState() => CatalogPageState();
}

class CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  final _openBillsKey = GlobalKey<CatalogOpenBillsSectionState>();
  late Future<int> _queueCountFuture;
  Timer? _offlineStatusTimer;
  StoreSettings? _autoCloseSettings;
  bool _autoCloseSettingsAreEstimated = false;
  String? _autoCloseSettingsError;

  @override
  void dispose() {
    _offlineStatusTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _queueCountFuture = _countQueueItems();
    if (widget.user.role == 'Kasir') {
      _loadAutoCloseSettings();
    }
    if (canUseOfflineSales(widget.user.role)) {
      _offlineStatusTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _refreshOfflineStatus(),
      );
    }
  }

  Future<void> refreshCatalog() async {
    final catalogCubit = context.read<CatalogCubit>();
    await catalogCubit.refresh();
    if (!mounted) return;
    final catalogState = catalogCubit.state;
    if (catalogState is CatalogLoaded) {
      context.read<CartCubit>().updateStockFromProducts(catalogState.products);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
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
            const Text('Pilih produk'),
          ],
        ),
        actions: [
          if (widget.user.role == 'Admin' &&
              widget.onOpenOfflineReconciliation != null)
            IconButton(
              tooltip: 'Rekonsiliasi transaksi offline',
              onPressed: widget.onOpenOfflineReconciliation,
              icon: const Icon(Icons.fact_check_outlined),
            ),
          if (canUseOfflineSales(widget.user.role) &&
              widget.offlineTransactionSyncService != null)
            CatalogOfflineQueueButton(
              queueCount: _queueCountFuture,
              onOpenQueue: () => _openQueuePage(context),
            ),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                tooltip: 'Buka keranjang',
                onPressed: () => _showCart(context),
                icon: Badge(
                  isLabelVisible: cart.totalQuantity > 0,
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '${cart.totalQuantity}',
                      key: ValueKey(cart.totalQuantity),
                    ),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _offlineStatusBanner(context),
          CatalogActiveShiftBanner(
            shift: widget.activeShift,
            onManageShift: widget.onManageShift,
          ),
          CatalogOpenBillsSection(
            key: _openBillsKey,
            checkoutRepository: widget.checkoutRepository,
          ),
          Expanded(
            child: BlocBuilder<CatalogCubit, CatalogState>(
              builder: (context, state) {
                return switch (state) {
                  CatalogLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  CatalogFailure() => _CatalogFailure(message: state.message),
                  CatalogLoaded() => CatalogProductBrowser(
                    state: state,
                    searchController: _searchController,
                    onProductTap: (product) => _addToCart(context, product),
                  ),
                };
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) => CatalogCartSummary(
          cart: cart,
          onOpenCart: () => _showCart(context),
        ),
      ),
    );
  }

  void _refreshCatalogProducts() {
    if (!mounted) return;
    context.read<CatalogCubit>().refreshProducts();
    _refreshOfflineStatus();
  }

  Future<int> _countQueueItems() async {
    final outletId = widget.outletId ?? widget.activeShift.outletId;
    if (!canUseOfflineSales(widget.user.role) ||
        outletId == null ||
        outletId.isEmpty) {
      return 0;
    }
    return widget.offlineTransactionQueueRepository
        .getUnresolvedTransactionCount(
          ownerUserId: widget.user.id,
          outletId: outletId,
          shiftId: widget.activeShift.id,
        );
  }

  void _refreshOfflineStatus() {
    if (!mounted || !canUseOfflineSales(widget.user.role)) return;
    setState(() {
      _queueCountFuture = _countQueueItems();
    });
  }

  Future<void> _loadAutoCloseSettings() async {
    if (widget.user.role != 'Kasir') return;

    final result = await widget.autoCloseSettingsProvider.getAutoCloseSettings(
      role: widget.user.role,
      userId: widget.user.id,
      outletId: widget.outletId ?? widget.activeShift.outletId,
    );
    if (!mounted) return;
    final settings = result.settings;
    setState(() {
      _autoCloseSettings = settings;
      _autoCloseSettingsAreEstimated = result.isEstimated;
      _autoCloseSettingsError =
          settings != null &&
              AutoCloseShiftSchedule.nextClosingAt(
                    settings.autoCloseShiftTime,
                    DateTime.now(),
                  ) ==
                  null
          ? 'Format waktu auto-close tidak valid.'
          : result.errorMessage;
    });
  }

  Future<void> _openQueuePage(BuildContext context) async {
    final syncService = widget.offlineTransactionSyncService;
    if (!canUseOfflineSales(widget.user.role) || syncService == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfflineTransactionQueuePage(
          user: widget.user,
          outletId: widget.outletId ?? widget.activeShift.outletId ?? '',
          shiftId: widget.activeShift.id,
          queueRepository: widget.offlineTransactionQueueRepository,
          syncService: syncService,
          offlineMasterDataCache: widget.offlineMasterDataCache,
        ),
      ),
    );
    _refreshOfflineStatus();
  }

  Widget _offlineStatusBanner(BuildContext context) {
    if (!canUseOfflineSales(widget.user.role) ||
        widget.offlineTransactionSyncService == null) {
      return const SizedBox.shrink();
    }

    final statusListenable =
        widget.offlineMasterDataCache?.networkStatusListenable;
    if (statusListenable == null) {
      final isOffline =
          widget.checkoutRepository is CheckoutModeProvider &&
          (widget.checkoutRepository as CheckoutModeProvider).isOffline;
      return CatalogOfflineStatusBanner(
        status: isOffline
            ? OfflineNetworkStatus.offline
            : OfflineNetworkStatus.online,
        queueCount: _queueCountFuture,
        autoCloseSettingsError: _autoCloseSettingsError,
        onOpenQueue: () => _openQueuePage(context),
        buildAutoCloseWarning: (context, count) => CatalogAutoCloseWarning(
          settings: _autoCloseSettings,
          isEstimated: _autoCloseSettingsAreEstimated,
          queueCount: count,
          onOpenQueue: () => _openQueuePage(context),
        ),
      );
    }

    return ValueListenableBuilder<OfflineNetworkStatus>(
      valueListenable: statusListenable,
      builder: (context, status, _) => CatalogOfflineStatusBanner(
        status: status,
        queueCount: _queueCountFuture,
        autoCloseSettingsError: _autoCloseSettingsError,
        onOpenQueue: () => _openQueuePage(context),
        buildAutoCloseWarning: (context, count) => CatalogAutoCloseWarning(
          settings: _autoCloseSettings,
          isEstimated: _autoCloseSettingsAreEstimated,
          queueCount: count,
          onOpenQueue: () => _openQueuePage(context),
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, CatalogProduct product) async {
    final cartCubit = context.read<CartCubit>();
    final issue = cartCubit.state.validateProductQuantity(product, quantity: 1);
    if (issue != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(issue.message)));
      return;
    }

    final selected = product.variantGroups.isEmpty
        ? const <SelectedProductVariant>[]
        : await showProductVariantDialog(context, product);
    if (selected == null || !context.mounted) return;
    final message = cartCubit.addProduct(product, selectedVariants: selected);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    HapticFeedback.selectionClick();
  }

  void _showCart(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cartCubit,
        child: ProductCartSheet(
          checkoutRepository: widget.checkoutRepository,
          outletId: widget.outletId,
          onCheckoutReturn: () async {
            await _openBillsKey.currentState?.reload();
            _refreshOfflineStatus();
          },
          onTransactionSuccess: _refreshCatalogProducts,
        ),
      ),
    );
  }
}

class _CatalogFailure extends StatelessWidget {
  const _CatalogFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Katalog belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: context.read<CatalogCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
