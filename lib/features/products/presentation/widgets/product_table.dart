import 'package:flutter/material.dart';

import '../../../../framework/widgets/responsive_data_table.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) => ResponsiveDataTable(
        minWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
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
                        ProductThumbnail(url: productImageUrl(item), size: 42),
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
                    child: MasterDataRowActions(
                      onEdit: () => onEdit(item),
                      onDelete: () => onDelete(item),
                      leadingActions: [
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
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
