import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../domain/entities/managed_category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../bloc/categories_cubit.dart';
import '../widgets/category_dialog.dart';

class CategoriesManagementPage extends StatelessWidget {
  const CategoriesManagementPage({super.key, required this.repository});

  final CategoriesRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoriesCubit(repository)..load(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView();

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoriesCubit, CategoriesState>(
      listener: (context, state) {
        final message = switch (state) {
          CategoriesLoaded(errorMessage: final error?) => error,
          CategoriesFailure(:final message) => message,
          _ => null,
        };
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<CategoriesCubit>().load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) => switch (state) {
              CategoriesLoading() => const MasterDataLoadingState(),
              CategoriesFailure(:final message) => MasterDataErrorState(
                title: 'Daftar kategori belum dapat dimuat.',
                message: message,
                onRetry: context.read<CategoriesCubit>().load,
              ),
              CategoriesLoaded(:final categories) => _buildLoaded(
                context,
                categories,
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<ManagedCategory> categories) {
    final visible = categories
        .where(
          (category) => '${category.name} ${category.description}'
              .toLowerCase()
              .contains(_query),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: context.read<CategoriesCubit>().load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _header(context),
              const SizedBox(height: 20),
              _searchPanel(),
              const SizedBox(height: 20),
              if (categories.isEmpty)
                MasterDataEmptyState(
                  icon: Icons.category_outlined,
                  title: 'Belum ada kategori.',
                  message: 'Tambahkan kategori untuk mengelompokkan produk.',
                  onAction: () => _editCategory(context),
                  actionLabel: 'Tambah Category',
                )
              else if (visible.isEmpty)
                const MasterDataEmptyState(
                  icon: Icons.search_off,
                  title: 'Kategori tidak ditemukan.',
                  message: 'Coba kata pencarian lainnya.',
                )
              else
                _categoriesTable(context, visible, constraints.maxWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return MasterDataHeader(
      title: 'Categories',
      description: 'Kelola kategori produk untuk kebutuhan menu & inventaris.',
      addLabel: 'Tambah Category',
      onRefresh: () => context.read<CategoriesCubit>().load(),
      onAdd: () => _editCategory(context),
    );
  }

  Widget _searchPanel() => MasterDataSearchPanel(
    controller: _searchController,
    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
    query: _query,
    hintText: 'Cari nama atau deskripsi category...',
  );

  Widget _categoriesTable(
    BuildContext context,
    List<ManagedCategory> categories,
    double availableWidth,
  ) {
    return ResponsiveDataTable(
      minWidth: availableWidth - 40,
      columns: const [
        DataColumn(label: Text('NAMA')),
        DataColumn(label: Text('DESKRIPSI')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('AKSI')),
      ],
      rows: categories.map(_categoryRow).toList(growable: false),
    );
  }

  DataRow _categoryRow(ManagedCategory category) => DataRow(
    cells: [
      DataCell(SizedBox(width: 230, child: Text(category.name))),
      DataCell(
        SizedBox(
          width: 420,
          child: Text(
            category.description.isEmpty ? '-' : category.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(MasterDataStatusBadge(isActive: category.isActive)),
      DataCell(
        MasterDataRowActions(
          onEdit: () => _editCategory(context, category),
          onDelete: () => _deleteCategory(context, category),
        ),
      ),
    ],
  );

  Future<void> _editCategory(
    BuildContext context, [
    ManagedCategory? category,
  ]) async {
    final draft = await showDialog<CategoryDraft>(
      context: context,
      builder: (_) => CategoryDialog(category: category),
    );
    if (draft == null || !context.mounted) return;
    final success = await context.read<CategoriesCubit>().saveCategory(
      categoryId: category?.id,
      name: draft.name,
      description: draft.description,
      isActive: draft.isActive,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null
                ? 'Kategori berhasil ditambahkan.'
                : 'Kategori berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    ManagedCategory category,
  ) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus kategori?',
      message:
          'Jika kategori "${category.name}" masih digunakan produk, produk tersebut dapat kehilangan kategori.',
    );
    if (confirmed != true || !context.mounted) return;
    final success = await context.read<CategoriesCubit>().deleteCategory(
      category.id,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori berhasil dihapus.')),
      );
    }
  }

}
