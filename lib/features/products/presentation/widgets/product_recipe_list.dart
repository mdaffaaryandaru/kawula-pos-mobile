// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/inventories/domain/entities/inventory_item.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class ProductRecipeList extends StatelessWidget {
  const ProductRecipeList({
    super.key,
    required this.recipes,
    required this.isBusy,
    required this.onRemove,
  });

  final List<ProductRecipe> recipes;
  final bool isBusy;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada bahan untuk produk ini.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: recipes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FBF3),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.inventoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${recipe.quantityLabel} per produk',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus bahan',
                onPressed: isBusy ? null : () => onRemove(index),
                color: AppColors.danger,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        );
      },
    );
  }
}
