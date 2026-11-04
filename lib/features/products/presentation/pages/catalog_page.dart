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
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_variant_dialog.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_open_bills_panel.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_product_grid.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/cashier_open_bill_dialogs.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.user,
    required this.checkoutRepository,
    required this.outletId,
    required this.activeShift,
    required this.onManageShift,
  });

  final AuthUser user;
  final CheckoutRepository checkoutRepository;
  final String? outletId;
  final ActiveShift activeShift;
  final VoidCallback onManageShift;

  @override
  State<CatalogPage> createState() => CatalogPageState();
}

class CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  List<TransactionRecord> _openBills = const [];
  bool _isLoadingOpenBills = false;
  String? _openBillsError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
                  CatalogLoaded() => _catalog(context, state),
                };
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            reverseDuration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topCenter,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: cart.isEmpty
                ? const SizedBox.shrink(key: ValueKey('empty-cart-bar'))
                : SafeArea(
                    key: const ValueKey('active-cart-bar'),
                    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      onPressed: () => _showCart(context),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, .2),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: Text(
                            'Keranjang (${cart.totalQuantity}) · '
                            '${formatRupiah(cart.estimatedSubtotal)}',
                            key: ValueKey(
                              '${cart.totalQuantity}-${cart.estimatedSubtotal}',
                            ),
                          ),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        elevation: 3,
                        shadowColor: AppColors.primary.withValues(alpha: .25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
          );
        },
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

    final transaction = await showCashierOpenBillsDialog(context, _openBills);
    if (transaction == null || !context.mounted) return;
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

      final input = await showCashierOpenBillPaymentDialog(
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

  Widget _catalog(BuildContext context, CatalogLoaded state) {
    final products = state.visibleProducts;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 180;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                compact ? 4 : 8,
                16,
                compact ? 6 : 12,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: context.read<CatalogCubit>().search,
                decoration: InputDecoration(
                  hintText: 'Cari nama produk atau kategori',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: _searchController.text.isEmpty
                        ? const SizedBox.shrink(key: ValueKey('no-search'))
                        : IconButton(
                            key: const ValueKey('clear-search'),
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              context.read<CatalogCubit>().search('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: compact ? 10 : 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: compact ? 40 : 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: 'Semua',
                    selected: state.selectedCategoryId == null,
                    onSelected: () =>
                        context.read<CatalogCubit>().selectCategory(null),
                  ),
                  for (final category in state.categories)
                    _CategoryChip(
                      label: category.name,
                      selected: state.selectedCategoryId == category.id,
                      onSelected: () => context
                          .read<CatalogCubit>()
                          .selectCategory(category.id),
                    ),
                ],
              ),
            ),
            SizedBox(height: compact ? 4 : 8),
            Expanded(
              child: CatalogProductGrid(
                products: products,
                contentKey: '${state.selectedCategoryId}-${state.searchQuery}',
                onProductTap: (product) => _addToCart(context, product),
              ),
            ),
          ],
        );
      },
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
          onCheckoutReturn: _loadOpenBills,
          onTransactionSuccess: _refreshCatalogProducts,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onSelected,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
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
