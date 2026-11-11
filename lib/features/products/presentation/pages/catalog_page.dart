import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/products/presentation/bloc/catalog_cubit.dart';
import 'package:kawula_pos/features/products/presentation/bloc/catalog_state.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_cart_sheet.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_variant_dialog.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_cart_summary.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_offline_status_widgets.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_open_bills_panel.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_product_browser.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/auto_close_shift_schedule.dart';
import 'package:kawula_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/transactions/data/services/offline_transaction_sync_service.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/offline_transaction_queue_page.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/open_bill_dialogs.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/platform_network_exception.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.user,
    required this.checkoutRepository,
    required this.outletId,
    required this.activeShift,
    required this.onManageShift,
    this.onOpenOfflineReconciliation,
    this.offlineTransactionsDao,
    this.offlineTransactionSyncService,
    this.storeSettingsRepository,
    this.offlineMasterDataCache,
  });

  final AuthUser user;
  final CheckoutRepository checkoutRepository;
  final String? outletId;
  final ActiveShift activeShift;
  final VoidCallback onManageShift;
  final VoidCallback? onOpenOfflineReconciliation;
  final OfflineTransactionsDao? offlineTransactionsDao;
  final OfflineTransactionSyncService? offlineTransactionSyncService;
  final StoreSettingsRepository? storeSettingsRepository;
  final OfflineMasterDataCache? offlineMasterDataCache;

  @override
  State<CatalogPage> createState() => CatalogPageState();
}

class CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  List<TransactionRecord> _openBills = const [];
  bool _isLoadingOpenBills = false;
  String? _openBillsError;
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
    _loadOpenBills();
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
              widget.offlineTransactionsDao != null &&
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
          _activeShiftBanner(context),
          CatalogOpenBillsPanel(
            billCount: _openBills.length,
            isLoading: _isLoadingOpenBills,
            errorMessage: _openBillsError,
            onRetry: _loadOpenBills,
            onViewBills: () => _showOpenBills(context),
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

  Future<void> _loadOpenBills() async {
    if (!mounted) return;
    setState(() {
      _isLoadingOpenBills = true;
      _openBillsError = null;
    });
    try {
      final transactions = await widget.checkoutRepository.getTransactions();
      if (!mounted) return;
      setState(() {
        _openBills = transactions
            .where((transaction) => transaction.isPending)
            .toList(growable: false);
        _openBillsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _openBillsError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingOpenBills = false);
    }
  }

  void _refreshCatalogProducts() {
    if (!mounted) return;
    context.read<CatalogCubit>().refreshProducts();
    _refreshOfflineStatus();
  }

  Future<int> _countQueueItems() async {
    final dao = widget.offlineTransactionsDao;
    final outletId = widget.outletId ?? widget.activeShift.outletId;
    if (dao == null ||
        !canUseOfflineSales(widget.user.role) ||
        outletId == null ||
        outletId.isEmpty) {
      return 0;
    }
    return (await dao.getUnresolvedTransactions(
      ownerUserId: widget.user.id,
      outletId: outletId,
      shiftId: widget.activeShift.id,
    )).length;
  }

  void _refreshOfflineStatus() {
    if (!mounted || !canUseOfflineSales(widget.user.role)) return;
    setState(() {
      _queueCountFuture = _countQueueItems();
    });
  }

  Future<void> _loadAutoCloseSettings() async {
    final repository = widget.storeSettingsRepository;
    final cache = widget.offlineMasterDataCache;
    if (widget.user.role != 'Kasir') return;

    if (cache?.shouldUseOfflineData == true) {
      await _loadCachedAutoCloseSettings();
      return;
    }

    if (repository == null) {
      await _loadCachedAutoCloseSettings(
        unavailableReason: 'Repository pengaturan shift tidak tersedia.',
      );
      return;
    }

    try {
      final settings = await repository.getSettings();
      final scopedCache = cache;
      String? cacheError;
      if (scopedCache != null && scopedCache.isScoped) {
        try {
          await scopedCache.save(
            cacheType: 'cashier_store_settings',
            dataKey: 'store_settings',
            payload: StoreSettingsModel.fromEntity(settings).toJson(),
          );
        } on Exception catch (error) {
          cacheError = 'Cache pengaturan auto-close gagal disimpan: $error';
        }
      }
      if (!mounted) return;
      setState(() {
        _autoCloseSettings = settings;
        _autoCloseSettingsAreEstimated = false;
        _autoCloseSettingsError =
            AutoCloseShiftSchedule.nextClosingAt(
                  settings.autoCloseShiftTime,
                  DateTime.now(),
                ) ==
                null
            ? 'Format waktu auto-close tidak valid.'
            : cacheError;
      });
    } on http.ClientException catch (error) {
      cache?.markOffline();
      await _loadCachedAutoCloseSettings(unavailableReason: error.toString());
    } on TimeoutException catch (error) {
      cache?.markOffline();
      await _loadCachedAutoCloseSettings(unavailableReason: error.toString());
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _autoCloseSettingsError = error.message;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _autoCloseSettingsError = error.message;
      });
    } on Exception catch (error) {
      if (isPlatformNetworkException(error)) {
        cache?.markOffline();
        await _loadCachedAutoCloseSettings(unavailableReason: error.toString());
        return;
      }
      if (!mounted) return;
      setState(() {
        _autoCloseSettingsError =
            'Pengaturan auto-close tidak dapat dimuat: $error';
      });
    }
  }

  Future<void> _loadCachedAutoCloseSettings({String? unavailableReason}) async {
    final cache = widget.offlineMasterDataCache;
    if (cache == null || !cache.isScoped) {
      if (!mounted) return;
      setState(() {
        _autoCloseSettingsError =
            unavailableReason ?? 'Pengaturan auto-close belum tersedia.';
      });
      return;
    }
    final Object? payload;
    try {
      payload = await cache.read(
        cacheType: 'cashier_store_settings',
        dataKey: 'store_settings',
      );
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _autoCloseSettingsError =
            'Cache pengaturan auto-close gagal dibaca: $error';
      });
      return;
    }
    if (!mounted) return;
    if (payload is! Map) {
      setState(() {
        _autoCloseSettings = null;
        _autoCloseSettingsAreEstimated = true;
        _autoCloseSettingsError =
            unavailableReason ?? 'Pengaturan auto-close belum memiliki cache.';
      });
      return;
    }

    try {
      final settings = StoreSettingsModel.fromJson(
        Map<String, dynamic>.from(payload),
      );
      setState(() {
        _autoCloseSettings = settings;
        _autoCloseSettingsAreEstimated = true;
        _autoCloseSettingsError =
            AutoCloseShiftSchedule.nextClosingAt(
                  settings.autoCloseShiftTime,
                  DateTime.now(),
                ) ==
                null
            ? 'Format waktu auto-close tidak valid.'
            : null;
      });
    } on FormatException catch (error) {
      setState(() {
        _autoCloseSettings = null;
        _autoCloseSettingsAreEstimated = true;
        _autoCloseSettingsError = error.message;
      });
    }
  }

  Future<void> _openQueuePage(BuildContext context) async {
    final dao = widget.offlineTransactionsDao;
    final syncService = widget.offlineTransactionSyncService;
    if (!canUseOfflineSales(widget.user.role) ||
        dao == null ||
        syncService == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfflineTransactionQueuePage(
          user: widget.user,
          outletId: widget.outletId ?? widget.activeShift.outletId ?? '',
          shiftId: widget.activeShift.id,
          dao: dao,
          syncService: syncService,
          offlineMasterDataCache: widget.offlineMasterDataCache,
        ),
      ),
    );
    _refreshOfflineStatus();
  }

  Widget _offlineStatusBanner(BuildContext context) {
    final dao = widget.offlineTransactionsDao;
    if (dao == null || !canUseOfflineSales(widget.user.role)) {
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
        buildAutoCloseWarning: (context, count) =>
            _buildAutoCloseWarning(context, queueCount: count),
      );
    }

    return ValueListenableBuilder<OfflineNetworkStatus>(
      valueListenable: statusListenable,
      builder: (context, status, _) => CatalogOfflineStatusBanner(
        status: status,
        queueCount: _queueCountFuture,
        autoCloseSettingsError: _autoCloseSettingsError,
        onOpenQueue: () => _openQueuePage(context),
        buildAutoCloseWarning: (context, count) =>
            _buildAutoCloseWarning(context, queueCount: count),
      ),
    );
  }

  Widget? _buildAutoCloseWarning(
    BuildContext context, {
    required int queueCount,
  }) {
    final settings = _autoCloseSettings;
    if (settings == null ||
        !settings.autoCloseShiftEnabled ||
        queueCount == 0) {
      return null;
    }
    final now = DateTime.now();
    final autoCloseAt = AutoCloseShiftSchedule.nextClosingAt(
      settings.autoCloseShiftTime,
      now,
    );
    if (autoCloseAt == null ||
        !AutoCloseShiftSchedule.shouldWarn(
          enabled: settings.autoCloseShiftEnabled,
          unresolvedCount: queueCount,
          configuredTime: settings.autoCloseShiftTime,
          now: now,
        )) {
      return null;
    }
    final remaining = autoCloseAt.difference(now);
    final time =
        '${autoCloseAt.hour.toString().padLeft(2, '0')}:'
        '${autoCloseAt.minute.toString().padLeft(2, '0')}';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final remainingText = hours > 0
        ? '$hours jam $minutes menit'
        : minutes > 0
        ? '$minutes menit'
        : 'kurang dari 1 menit';
    final estimated = _autoCloseSettingsAreEstimated
        ? ' Estimasi dari cache terakhir.'
        : ' Estimasi waktu lokal; zona waktu server belum diverifikasi.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Shift diperkirakan ditutup otomatis pukul $time '
              '(sekitar $remainingText). Masih ada $queueCount transaksi '
              'yang belum terselesaikan.$estimated',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _openQueuePage(context),
            child: const Text('Lihat antrean'),
          ),
        ],
      ),
    );
  }

  Future<void> _showOpenBills(BuildContext context) async {
    await _loadOpenBills();
    if (!context.mounted) return;
    if (_openBillsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open bill gagal dimuat: $_openBillsError')),
      );
      return;
    }
    if (_openBills.isEmpty) return;

    final transaction = await showOpenBillsDialog(context, _openBills);
    if (transaction == null || !context.mounted) return;
    if (transaction.id.startsWith('OFF-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open Bill lokal belum dapat dilunasi, dibatalkan, atau diproses melalui server.',
          ),
        ),
      );
      return;
    }
    await _settleOpenBill(context, transaction);
  }

  Future<void> _settleOpenBill(
    BuildContext context,
    TransactionRecord transaction,
  ) async {
    try {
      final methods = (await widget.checkoutRepository.getPaymentMethods())
          .where((method) => !method.isOpenBill)
          .toList(growable: false);
      if (!context.mounted) return;
      if (methods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada metode pembayaran aktif.')),
        );
        return;
      }

      final input = await showOpenBillPaymentDialog(
        context,
        transaction: transaction,
        methods: methods,
      );
      if (input == null || !context.mounted) return;

      await widget.checkoutRepository.payPendingTransaction(
        transactionId: transaction.id,
        paymentMethod: input.paymentMethod,
        paidAmount: input.paidAmount,
        pin: input.pin,
      );
      await _loadOpenBills();
      if (!context.mounted) return;
      if (_openBillsError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran berhasil, tetapi daftar open bill gagal diperbarui: $_openBillsError',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran open bill berhasil.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pembayaran gagal: $error')));
    }
  }

  Widget _activeShiftBanner(BuildContext context) {
    final theme = Theme.of(context);
    final shift = widget.activeShift;
    final startTime = shift.startTime.toLocal();
    final time =
        '${startTime.hour.toString().padLeft(2, '0')}:'
        '${startTime.minute.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8FBF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Shift Aktif',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const SizedBox(width: 4),
                    const _LiveStatusDot(),
                  ],
                ),
                Text(
                  '${shift.outletName ?? 'Outlet'} · Mulai $time · '
                  'Kas awal ${formatRupiah(shift.startingCash)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: widget.onManageShift,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Tutup Shift'),
          ),
        ],
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
            await _loadOpenBills();
            _refreshOfflineStatus();
          },
          onTransactionSuccess: _refreshCatalogProducts,
        ),
      ),
    );
  }
}

class _LiveStatusDot extends StatelessWidget {
  const _LiveStatusDot();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .45, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOut,
    builder: (context, opacity, child) =>
        Opacity(opacity: opacity, child: child),
    child: const Icon(Icons.circle, size: 8, color: AppColors.success),
  );
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
