import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/api_config.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
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
  });

  final AuthUser user;
  final CheckoutRepository checkoutRepository;
  final String? outletId;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih produk'),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) => IconButton(
              tooltip: 'Buka keranjang',
              onPressed: () => _showCart(context),
              icon: Badge(
                isLabelVisible: cart.totalQuantity > 0,
                label: Text('${cart.totalQuantity}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CatalogCubit, CatalogState>(
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
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          if (cart.isEmpty) return const SizedBox.shrink();
          return SafeArea(
            minimum: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => _showCart(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Keranjang (${cart.totalQuantity}) · ${formatRupiah(cart.estimatedSubtotal)}',
                ),
              ),
            ),
          );
        },
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
              hintText: 'Cari produk',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        context.read<CatalogCubit>().search('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: const OutlineInputBorder(),
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
              : LayoutBuilder(
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
                        childAspectRatio: constraints.maxWidth >= 600
                            ? 0.88
                            : 0.72,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) => _ProductCard(
                        product: products[index],
                        onTap: () => _addToCart(context, products[index]),
                      ),
                    );
                  },
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
  }

  void _showCart(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: cartCubit,
        child: ProductCartSheet(
          checkoutRepository: widget.checkoutRepository,
          outletId: widget.outletId,
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imageUri == null
                  ? ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: const Icon(Icons.fastfood_outlined, size: 42),
                    )
                  : Image.network(
                      imageUri.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 42,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (product.category case final category?)
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupiah(product.discountedPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (discounted)
                    Text(
                      formatRupiah(product.price),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(decoration: TextDecoration.lineThrough),
                    ),
                ],
              ),
            ),
          ],
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
