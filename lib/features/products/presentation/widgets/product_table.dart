import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../products/domain/entities/product_management.dart';
import 'product_management_helpers.dart';
import 'product_management_widgets.dart';

class ProductsTable extends StatelessWidget {
  const ProductsTable({
    super.key,
    required this.products,
    required this.onEdit,
    required this.onDelete,
    required this.onRecipes,
  });

  final List<ManagedProduct> products;
  final ValueChanged<ManagedProduct> onEdit;
  final ValueChanged<ManagedProduct> onDelete;
  final ValueChanged<ManagedProduct> onRecipes;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: .7,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFC)),
          horizontalMargin: 20,
          columnSpacing: 28,
          columns: [
            DataColumn(label: Text('NAMA', style: headerStyle)),
            DataColumn(label: Text('KATEGORI', style: headerStyle)),
            DataColumn(label: Text('HARGA', style: headerStyle)),
            DataColumn(label: Text('STOK', style: headerStyle)),
            DataColumn(label: Text('DISKON', style: headerStyle)),
            DataColumn(label: Text('STATUS', style: headerStyle)),
            DataColumn(label: Text('AKSI', style: headerStyle)),
          ],
          rows: [
            for (final item in products)
              DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 230,
                      child: Row(
                        children: [
                          ProductThumbnail(
                            url: productImageUrl(item),
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  item.product.images.isEmpty
                                      ? 'Tanpa gambar'
                                      : '${item.product.images.length} foto',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    CategoryBadge(
                      label: item.product.category?.name ?? 'Tidak berkategori',
                    ),
                  ),
                  DataCell(
                    Text(
                      formatProductRupiah(item.product.price),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataCell(Text(formatProductNumber(item.product.stock ?? 0))),
                  DataCell(
                    Text(
                      item.product.discount == null ? '-' : 'Aktif',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(ProductStatusBadge(isActive: item.product.isActive)),
                  DataCell(
                    SizedBox(
                      width: 280,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => onRecipes(item),
                            icon: const Icon(Icons.science_outlined, size: 16),
                            label: Text('Bahan (${item.recipes.length})'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(color: Color(0xFFA7F3D0)),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.border,
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Edit produk',
                            onPressed: () => onEdit(item),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined, size: 19),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            tooltip: 'Hapus produk',
                            onPressed: () => onDelete(item),
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              backgroundColor: const Color(0xFFFFF1F2),
                              side: const BorderSide(color: Color(0xFFFECdd3)),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 19),
                          ),
                        ],
                      ),
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

class ProductEmptyState extends StatelessWidget {
  const ProductEmptyState({super.key, required this.hasProducts});

  final bool hasProducts;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 36,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 10),
        Text(
          hasProducts ? 'Produk tidak ditemukan.' : 'Belum ada produk.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

String productImageUrl(ManagedProduct item) =>
    item.product.images.where((image) => image.isMain).firstOrNull?.url ??
    item.product.imageUrl;
