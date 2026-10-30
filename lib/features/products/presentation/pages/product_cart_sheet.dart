import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/app_colors.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../transactions/presentation/bloc/checkout_cubit.dart';
import '../../../transactions/presentation/pages/checkout_page.dart';
import '../bloc/cart_cubit.dart';
import 'product_formatters.dart';

class ProductCartSheet extends StatelessWidget {
  const ProductCartSheet({
    super.key,
    required this.checkoutRepository,
    required this.outletId,
    this.onCheckoutReturn,
  });

  final CheckoutRepository checkoutRepository;
  final String? outletId;
  final VoidCallback? onCheckoutReturn;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return BlocBuilder<CartCubit, CartState>(
          builder: (context, cart) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keranjang (${cart.totalQuantity})',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (!cart.isEmpty)
                        TextButton(
                          onPressed: () => _confirmClear(context),
                          child: const Text('Kosongkan'),
                        ),
                      IconButton(
                        tooltip: 'Tutup keranjang',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: cart.isEmpty
                      ? const Center(child: Text('Keranjang masih kosong.'))
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.items.length,
                          separatorBuilder: (_, _) => const Divider(height: 20),
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              child: Container(
                                key: ValueKey(item.selectionKey),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if (item
                                                  .selectedVariants
                                                  .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    item.selectedVariants
                                                        .map(
                                                          (variant) =>
                                                              '${variant.groupName}: ${variant.optionName}',
                                                        )
                                                        .join(', '),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Hapus produk',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => context
                                              .read<CartCubit>()
                                              .remove(item.selectionKey),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${formatRupiah(item.unitPrice)} × '
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        IconButton.filledTonal(
                                          tooltip: 'Kurangi jumlah',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => context
                                              .read<CartCubit>()
                                              .decrement(item.selectionKey),
                                          icon: const Icon(
                                            Icons.remove_rounded,
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            transitionBuilder:
                                                (child, animation) =>
                                                    ScaleTransition(
                                                      scale: animation,
                                                      child: child,
                                                    ),
                                            child: Text(
                                              '${item.quantity}',
                                              key: ValueKey(item.quantity),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton.filledTonal(
                                          tooltip: 'Tambah jumlah',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => context
                                              .read<CartCubit>()
                                              .increment(item.selectionKey),
                                          icon: const Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () => _editNotes(
                                          context,
                                          item.selectionKey,
                                          item.notes,
                                        ),
                                        icon: const Icon(
                                          Icons.edit_note_rounded,
                                          size: 19,
                                        ),
                                        label: Text(
                                          item.notes.isEmpty
                                              ? 'Tambah catatan'
                                              : 'Catatan: ${item.notes}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (!cart.isEmpty)
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Estimasi subtotal',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, .15),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: Text(
                                formatRupiah(cart.estimatedSubtotal),
                                key: ValueKey(cart.estimatedSubtotal),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total final dihitung oleh server saat checkout.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _openCheckout(context),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Lanjut ke pembayaran'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text('Semua produk di keranjang akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if (clear == true && context.mounted) {
      context.read<CartCubit>().clear();
    }
  }

  Future<void> _editNotes(
    BuildContext context,
    String selectionKey,
    String currentNotes,
  ) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => _CartNotesDialog(initialNotes: currentNotes),
    );
    if (notes != null && context.mounted) {
      context.read<CartCubit>().updateNotes(selectionKey, notes);
    }
  }

  void _openCheckout(BuildContext context) {
    final navigator = Navigator.of(context);
    final cartCubit = context.read<CartCubit>();
    navigator.pop();
    navigator
        .push<void>(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: cartCubit,
              child: BlocProvider(
                create: (_) => CheckoutCubit(checkoutRepository)..load(),
                child: CheckoutPage(outletId: outletId),
              ),
            ),
          ),
        )
        .then((_) => onCheckoutReturn?.call());
  }
}

class _CartNotesDialog extends StatefulWidget {
  const _CartNotesDialog({required this.initialNotes});

  final String initialNotes;

  @override
  State<_CartNotesDialog> createState() => _CartNotesDialogState();
}

class _CartNotesDialogState extends State<_CartNotesDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Catatan produk'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 200,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Contoh: tanpa gula'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
