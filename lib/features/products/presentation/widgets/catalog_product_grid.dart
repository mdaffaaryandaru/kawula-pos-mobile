// Dart imports:
import 'dart:ui' show ImageFilter;

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/config/api_config.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class CatalogProductGrid extends StatelessWidget {
  const CatalogProductGrid({
    super.key,
    required this.products,
    required this.contentKey,
    required this.onProductTap,
  });

  final List<CatalogProduct> products;
  final String contentKey;
  final ValueChanged<CatalogProduct> onProductTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('Produk tidak ditemukan.'));
    }

    return AnimatedSwitcher(
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
        key: ValueKey(contentKey),
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
                duration: Duration(milliseconds: 280 + index.clamp(0, 8) * 35),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) => Opacity(
                  opacity: progress,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - progress)),
                    child: child,
                  ),
                ),
                child: _CatalogProductCard(
                  product: product,
                  onTap: () => onProductTap(product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CatalogProductCard extends StatelessWidget {
  const _CatalogProductCard({required this.product, required this.onTap});

  final CatalogProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUri = product.imageUrl.isEmpty
        ? null
        : resolveProductImageUri(ApiConfig.baseUrl, product.imageUrl);
    final discounted = product.discountedPrice < product.price;
    return _AnimatedCatalogProductCard(
      product: product,
      imageUri: imageUri?.toString(),
      discounted: discounted,
      onTap: onTap,
    );
  }
}

class _AnimatedCatalogProductCard extends StatefulWidget {
  const _AnimatedCatalogProductCard({
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
  State<_AnimatedCatalogProductCard> createState() =>
      _AnimatedCatalogProductCardState();
}

class _AnimatedCatalogProductCardState
    extends State<_AnimatedCatalogProductCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stockStatus = product.stockStatus;
    final canPurchase = stockStatus == ProductStockStatus.available;
    final image = widget.imageUri == null
        ? ColoredBox(
            color: const Color(0xFFF0F4FA),
            child: Icon(
              Icons.fastfood_outlined,
              size: 42,
              color: AppColors.textSecondary.withValues(alpha: .6),
            ),
          )
        : Image.network(
            widget.imageUri!,
            fit: BoxFit.cover,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 260),
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
          );
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
            onTap: canPurchase ? widget.onTap : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (stockStatus == ProductStockStatus.outOfStock)
                        ClipRect(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: image,
                          ),
                        )
                      else
                        image,
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
                      if (!canPurchase)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(
                                  255,
                                  255,
                                  52,
                                  37,
                                ).withValues(alpha: .78),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                stockStatus == ProductStockStatus.outOfStock
                                    ? 'HABIS'
                                    : 'STOK TIDAK TERSEDIA',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .5,
                                ),
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
                            onPressed: canPurchase ? widget.onTap : null,
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
