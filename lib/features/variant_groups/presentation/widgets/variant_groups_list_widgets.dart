part of '../pages/variant_groups_management_page.dart';

class VariantGroupsList extends StatelessWidget {
  const VariantGroupsList({
    super.key,
    required this.header,
    required this.groups,
    required this.totalCount,
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
    required this.onClearSearch,
    required this.onEditGroup,
    required this.onDeleteGroup,
  });

  final Widget header;
  final List<VariantGroupDefinition> groups;
  final int totalCount;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<VariantGroupDefinition> onEditGroup;
  final ValueChanged<VariantGroupDefinition> onDeleteGroup;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
    children: [
      header,
      const SizedBox(height: 16),
      TextField(
        controller: searchController,
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Cari grup varian...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (totalCount == 0)
        const MasterDataEmptyState(
          icon: Icons.tune_outlined,
          title: 'Belum ada grup varian',
          message: 'Buat grup untuk pilihan seperti rasa, suhu, atau ukuran.',
        )
      else if (groups.isEmpty)
        const MasterDataEmptyState(
          icon: Icons.search_off,
          title: 'Grup Varian Tidak Ditemukan',
          message: 'Coba periksa kembali kata kunci pencarian Anda.',
        )
      else
        for (final group in groups) ...[
          _VariantGroupCard(
            group: group,
            onEdit: () => onEditGroup(group),
            onDelete: () => onDeleteGroup(group),
          ),
          const SizedBox(height: 10),
        ],
    ],
  );
}

class _VariantGroupCard extends StatelessWidget {
  const _VariantGroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  final VariantGroupDefinition group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.tune_outlined,
                    size: 19,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Min/Max: ${group.minSelection} - '
                        '${group.maxSelection} pilihan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _RequirementBadge(isRequired: group.isRequired),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'OPSI VARIAN (${group.options.length})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in group.options)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    label: Text(
                      option.priceAdjustment == 0
                          ? option.name
                          : '${option.name} (${option.priceAdjustment > 0 ? '+' : '-'}'
                                '${formatRupiah(option.priceAdjustment.abs())})',
                    ),
                  ),
              ],
            ),
            if (group.options.any((option) => option.recipes.isNotEmpty)) ...[
              const SizedBox(height: 8),
              for (final option in group.options)
                for (final recipe in option.recipes)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${option.name}: ${recipe.inventoryName} · '
                      '${recipe.quantity} ${recipe.unitName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
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

class _RequirementBadge extends StatelessWidget {
  const _RequirementBadge({required this.isRequired});

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isRequired
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isRequired ? 'Wajib' : 'Tidak Wajib',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isRequired
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
