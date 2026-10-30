import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../config/api_config.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../shifts/domain/entities/active_shift.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../transactions/domain/entities/checkout.dart';
import '../../../transactions/presentation/widgets/cashier_open_bill_dialogs.dart';
import '../../domain/entities/catalog_product.dart';
import '../bloc/cart_cubit.dart';
import '../bloc/catalog_cubit.dart';
import '../bloc/catalog_state.dart';
import 'product_cart_sheet.dart';
import 'product_formatters.dart';
import 'product_variant_dialog.dart';

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
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
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
          _openBillBanner(context),
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

  Widget _openBillBanner(BuildContext context) {
    if (_openBills.isEmpty && _openBillsError == null) {
      return const SizedBox.shrink();
    }
    final hasError = _openBillsError != null;
    final foreground = hasError
        ? Theme.of(context).colorScheme.error
        : const Color(0xFFB45309);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasError
            ? Theme.of(context).colorScheme.errorContainer
            : const Color(0xFFFFFBEB),
        border: Border.all(
          color: hasError
              ? Theme.of(context).colorScheme.error.withValues(alpha: .35)
              : const Color(0xFFFBBF24),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.schedule_outlined,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError
                      ? 'Open Bill tidak dapat dimuat'
                      : 'Open Bill (${_openBills.length})',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hasError
                      ? _openBillsError!
                      : 'Ada tagihan tertunda yang belum dilunasi',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _isLoadingOpenBills
                ? null
                : hasError
                ? _loadOpenBills
                : () => _showOpenBills(context),
            style: TextButton.styleFrom(
              foregroundColor: foreground,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              _isLoadingOpenBills
                  ? 'Memuat...'
                  : hasError
                  ? 'Coba Lagi'
                  : 'Lihat Tagihan',
            ),
          ),
        ],
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
          height: 48,
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
                  onSelected: () =>
                      context.read<CatalogCubit>().selectCategory(category.id),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('Produk tidak ditemukan.'))
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, .025),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: LayoutBuilder(
                    key: ValueKey(
                      '${state.selectedCategoryId}-${state.searchQuery}',
                    ),
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 4
                          : constraints.maxWidth >= 600
                          ? 3
                          : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: constraints.maxWidth >= 900
                              ? 0.84
                              : constraints.maxWidth >= 600
                              ? 0.78
                              : 0.70,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(product.id),
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                              milliseconds: 280 + index.clamp(0, 8) * 35,
                            ),
                            curve: Curves.easeOutCubic,
                            builder: (context, progress, child) => Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(0, 14 * (1 - progress)),
                                child: child,
                              ),
                            ),
                            child: _ProductCard(
                              product: product,
                              onTap: () => _addToCart(context, product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _addToCart(BuildContext context, CatalogProduct product) async {
    final selected = product.variantGroups.isEmpty
        ? const <SelectedProductVariant>[]
        : await showProductVariantDialog(context, product);
    if (selected == null || !context.mounted) return;
    context.read<CartCubit>().addProduct(product, selectedVariants: selected);
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final CatalogProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUri = product.imageUrl.isEmpty
        ? null
        : resolveProductImageUri(ApiConfig.baseUrl, product.imageUrl);
    final discounted = product.discountedPrice < product.price;
    return _AnimatedProductCard(
      product: product,
      imageUri: imageUri?.toString(),
      discounted: discounted,
      onTap: onTap,
    );
  }
}

class _AnimatedProductCard extends StatefulWidget {
  const _AnimatedProductCard({
    required this.product,
    required this.imageUri,
    required this.discounted,
    required this.onTap,
  });

  final CatalogProduct product;
  final String? imageUri;
  final bool discounted;
  final VoidCallback onTap;

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Card(
          color: AppColors.surface,
          elevation: _hovered ? 5 : 1,
          shadowColor: AppColors.primary.withValues(alpha: .14),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.imageUri == null
                          ? ColoredBox(
                              color: const Color(0xFFF0F4FA),
                              child: Icon(
                                Icons.fastfood_outlined,
                                size: 42,
                                color: AppColors.textSecondary.withValues(
                                  alpha: .6,
                                ),
                              ),
                            )
                          : Image.network(
                              widget.imageUri!,
                              fit: BoxFit.cover,
                              frameBuilder:
                                  (
                                    context,
                                    child,
                                    frame,
                                    wasSynchronouslyLoaded,
                                  ) {
                                    if (wasSynchronouslyLoaded) return child;
                                    return AnimatedOpacity(
                                      opacity: frame == null ? 0 : 1,
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeOut,
                                      child: child,
                                    );
                                  },
                              errorBuilder: (_, _, _) => const ColoredBox(
                                color: Color(0xFFF0F4FA),
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 42,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                      if (widget.discounted)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PROMO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .4,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 9, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              formatRupiah(product.discountedPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          if (widget.discounted) ...[
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                formatRupiah(product.price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.category?.name ??
                                  (product.variantGroups.isNotEmpty
                                      ? 'Pilih varian'
                                      : 'Produk'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 5),
                          IconButton.filled(
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 36,
                              height: 36,
                            ),
                            tooltip: 'Tambah ${product.name} ke keranjang',
                            onPressed: widget.onTap,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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

Uri resolveProductImageUri(String apiBaseUrl, String imageUrl) {
  final imageUri = Uri.parse(imageUrl);
  if (imageUri.hasScheme) return imageUri;
  final apiUri = Uri.parse(apiBaseUrl);
  final pathWithoutApi = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
  return apiUri.replace(
    path: '$pathWithoutApi/${imageUrl.replaceFirst(RegExp(r'^/+'), '')}',
    query: null,
    fragment: null,
  );
}
