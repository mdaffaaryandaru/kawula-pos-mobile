import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/bloc/catalog_cubit.dart';
import 'package:kawula_pos/features/products/presentation/bloc/catalog_state.dart';
import 'package:kawula_pos/features/products/presentation/widgets/catalog_product_grid.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class CatalogProductBrowser extends StatelessWidget {
  const CatalogProductBrowser({
    super.key,
    required this.state,
    required this.searchController,
    required this.onProductTap,
    required this.refreshVersion,
  });

  final CatalogLoaded state;
  final TextEditingController searchController;
  final ValueChanged<CatalogProduct> onProductTap;
  final int refreshVersion;

  @override
  Widget build(BuildContext context) {
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
                controller: searchController,
                onChanged: context.read<CatalogCubit>().search,
                decoration: InputDecoration(
                  hintText: 'Cari nama produk atau kategori',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: searchController.text.isEmpty
                        ? const SizedBox.shrink(key: ValueKey('no-search'))
                        : IconButton(
                            key: const ValueKey('clear-search'),
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              searchController.clear();
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
                products: state.visibleProducts,
                contentKey:
                    '${state.selectedCategoryId}-${state.searchQuery}-$refreshVersion',
                onProductTap: onProductTap,
              ),
            ),
          ],
        );
      },
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
