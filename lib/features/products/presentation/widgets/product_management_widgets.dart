import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../categories/domain/entities/managed_category.dart';
import '../../../products/domain/entities/product_management.dart';
import 'product_management_helpers.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onRecipes,
  });

  final ManagedProduct item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRecipes;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final imageUrl =
        product.images.where((image) => image.isMain).firstOrNull?.url ??
        product.imageUrl;
    return Card(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                ProductThumbnail(url: imageUrl, size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      CategoryBadge(
                        label: product.category?.name ?? 'Kategori tidak ada',
                      ),
                    ],
                  ),
                ),
                ProductStatusBadge(isActive: product.isActive),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ProductDataPoint(
                    label: 'Harga',
                    value: formatProductRupiah(product.price),
                  ),
                ),
                Expanded(
                  child: _ProductDataPoint(
                    label: 'Stok',
                    value: formatProductNumber(product.stock ?? 0),
                  ),
                ),
                Expanded(
                  child: _ProductDataPoint(
                    label: 'Diskon',
                    value: product.discount == null ? '-' : 'Aktif',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRecipes,
                  icon: const Icon(Icons.science_outlined, size: 17),
                  label: Text('Bahan (${item.recipes.length})'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4FA),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(11),
    ),
    child: url.isEmpty
        ? const Icon(Icons.image_outlined, color: AppColors.textSecondary)
        : Image.network(
            resolveProductImageUrl(url),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textSecondary,
            ),
          ),
  );
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF4FF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ProductStatusBadge extends StatelessWidget {
  const ProductStatusBadge({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductDataPoint extends StatelessWidget {
  const _ProductDataPoint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class ProductPageHeader extends StatelessWidget {
  const ProductPageHeader({
    super.key,
    required this.count,
    required this.onRefresh,
    required this.onAdd,
  });

  final int count;
  final VoidCallback onRefresh;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x070F172A),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Tambah Product'),
            ),
          ],
        );
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MASTER DATA',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Products',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola menu produk, category, stock, dan bahan baku.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 5),
            Text(
              '$count produk terdaftar',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
        if (constraints.maxWidth >= 700) {
          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [heading, const SizedBox(height: 16), actions],
        );
      },
    ),
  );
}

class ProductFilterBar extends StatelessWidget {
  const ProductFilterBar({
    super.key,
    required this.controller,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
    required this.onCategoryChanged,
  });

  final TextEditingController controller;
  final List<ManagedCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onChanged;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Cari nama / category...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: AppColors.dashboardBackground,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        );
        final category = DropdownButtonFormField<String?>(
          initialValue: selectedCategoryId,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.dashboardBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          hint: const Text('Semua Category'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Semua Category'),
            ),
            for (final item in categories)
              DropdownMenuItem<String?>(
                value: item.id,
                child: Text(item.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onCategoryChanged,
        );
        if (constraints.maxWidth >= 620) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(width: 220, child: category),
            ],
          );
        }
        return Column(
          children: [
            search,
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: category),
          ],
        );
      },
    ),
  );
}
