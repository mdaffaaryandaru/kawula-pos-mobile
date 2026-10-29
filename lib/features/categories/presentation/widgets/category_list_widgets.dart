import 'package:flutter/material.dart';

import '../../domain/entities/managed_category.dart';

class CategoryListTile extends StatelessWidget {
  const CategoryListTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagedCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            category.isActive ? Icons.category_outlined : Icons.category,
          ),
        ),
        title: Text(category.name),
        subtitle: Text(
          '${category.description.isEmpty ? 'Tanpa deskripsi' : category.description}'
          ' · ${category.isActive ? 'Aktif' : 'Nonaktif'}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Ubah')),
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}

class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      children: [
        Icon(Icons.category_outlined, size: 44),
        SizedBox(height: 12),
        Text('Belum ada kategori.'),
      ],
    ),
  );
}
