import 'package:flutter/material.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class CatalogCartSummary extends StatelessWidget {
  const CatalogCartSummary({
    super.key,
    required this.cart,
    required this.onOpenCart,
  });

  final CartState cart;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
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
                onPressed: onOpenCart,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => FadeTransition(
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
  }
}
