import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/managed_category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../bloc/categories_cubit.dart';

class CategoriesManagementPage extends StatelessWidget {
  const CategoriesManagementPage({super.key, required this.repository});

  final CategoriesRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoriesCubit(repository)..load(),
      child: BlocBuilder<CategoriesCubit, CategoriesState>(
        builder: (context, state) => switch (state) {
          CategoriesLoading() => const Scaffold(
            appBar: _CategoriesAppBar(),
            body: Center(child: CircularProgressIndicator()),
          ),
          CategoriesFailure() => Scaffold(
            appBar: const _CategoriesAppBar(),
            body: _loadFailure(context, state.message),
          ),
          CategoriesLoaded() => _CategoriesView(state: state),
        },
      ),
    );
  }

  Widget _loadFailure(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Kategori belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<CategoriesCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CategoriesAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Kategori'));
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView({required this.state});

  final CategoriesLoaded state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _CategoriesAppBar(),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: context.read<CategoriesCubit>().load,
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: context.read<CategoriesCubit>().load,
              child: state.categories.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Belum ada kategori.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: state.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final category = state.categories[index];
                        return _CategoryCard(
                          category: category,
                          onEdit: () => _editCategory(context, category),
                          onDelete: () => _deleteCategory(context, category),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCategory(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah kategori'),
      ),
    );
  }
}

Future<void> _editCategory(
  BuildContext context, [
  ManagedCategory? category,
]) async {
  final draft = await showDialog<_CategoryDraft>(
    context: context,
    builder: (_) => _CategoryDialog(category: category),
  );
  if (draft == null || !context.mounted) return;
  final success = await context.read<CategoriesCubit>().saveCategory(
    categoryId: category?.id,
    name: draft.name,
    description: draft.description,
    isActive: draft.isActive,
  );
  if (!context.mounted) return;
  _showResult(context, success, 'Kategori berhasil disimpan.');
}

Future<void> _deleteCategory(
  BuildContext context,
  ManagedCategory category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hapus kategori?'),
      content: Text(
        'Jika kategori "${category.name}" masih digunakan produk, produk tersebut dapat kehilangan kategori.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final success = await context.read<CategoriesCubit>().deleteCategory(
    category.id,
  );
  if (!context.mounted) return;
  _showResult(context, success, 'Kategori berhasil dihapus.');
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
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

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final ManagedCategory? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category == null ? 'Tambah kategori' : 'Ubah kategori',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama kategori'),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Nama minimal 2 karakter.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
              maxLines: 2,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kategori aktif'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _CategoryDraft(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                isActive: _isActive,
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String description;
  final bool isActive;
}

void _showResult(BuildContext context, bool success, String successMessage) {
  var message = successMessage;
  if (!success) {
    final state = context.read<CategoriesCubit>().state;
    message = switch (state) {
      CategoriesLoaded(errorMessage: final errorMessage) =>
        errorMessage ?? 'Operasi tidak berhasil.',
      CategoriesFailure(message: final errorMessage) => errorMessage,
      _ => 'Operasi tidak berhasil.',
    };
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
