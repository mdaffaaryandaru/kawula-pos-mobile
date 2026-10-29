import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../products/domain/entities/product_management.dart';
import '../../../products/domain/repositories/product_management_repository.dart';
import '../../domain/entities/variant_group_definition.dart';
import '../../domain/repositories/variant_groups_repository.dart';
import '../../../products/presentation/pages/product_formatters.dart';

part '../widgets/variant_groups_list_widgets.dart';
part '../widgets/variant_group_dialog.dart';
part '../widgets/variant_group_option_editors.dart';

class VariantGroupsManagementPage extends StatefulWidget {
  const VariantGroupsManagementPage({
    super.key,
    required this.repository,
    required this.productsRepository,
  });

  final VariantGroupsRepository repository;
  final ProductManagementRepository productsRepository;

  @override
  State<VariantGroupsManagementPage> createState() =>
      _VariantGroupsManagementPageState();
}

class _VariantGroupsManagementPageState
    extends State<VariantGroupsManagementPage> {
  late Future<_VariantGroupsData> _data;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_VariantGroupsData> _load() async {
    final groups = await widget.repository.getVariantGroupDefinitions();
    return _VariantGroupsData(groups: groups);
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grup Varian')),
      body: FutureBuilder<_VariantGroupsData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MasterDataLoadingState();
          }
          if (snapshot.hasError) {
            return MasterDataErrorState(
              title: 'Data grup varian belum dapat dimuat.',
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          final filteredGroups = data.groups
              .where(
                (group) =>
                    group.name.toLowerCase().contains(_query.toLowerCase()) ||
                    group.options.any(
                      (option) => option.name.toLowerCase().contains(
                        _query.toLowerCase(),
                      ),
                    ),
              )
              .toList(growable: false);
          return RefreshIndicator(
            onRefresh: () async {
              final future = _load();
              setState(() {
                _data = future;
              });
              await future;
            },
            child: VariantGroupsList(
              header: MasterDataHeader(
                title: 'Grup Varian',
                description:
                    'Kelola pilihan rasa, suhu, dan ukuran untuk katalog menu. '
                    '${data.groups.length} grup.',
                addLabel: 'Tambah Grup Varian',
                onRefresh: _reload,
                onAdd: () => _editGroup(data),
              ),
              groups: filteredGroups,
              totalCount: data.groups.length,
              query: _query,
              searchController: _searchController,
              onQueryChanged: (value) => setState(() => _query = value),
              onClearSearch: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              onEditGroup: (group) => _editGroup(data, group),
              onDeleteGroup: _deleteGroup,
            ),
          );
        },
      ),
    );
  }

  Future<void> _editGroup(
    _VariantGroupsData data, [
    VariantGroupDefinition? group,
  ]) async {
    late final VariantRecipeReferences references;
    try {
      references = await widget.repository.getVariantRecipeReferences();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Referensi resep tidak dapat dimuat: $error');
      return;
    }
    if (!mounted) return;
    final draft = await showDialog<_VariantGroupDraft>(
      context: context,
      builder: (_) => _VariantGroupDialog(group: group, references: references),
    );
    if (draft == null || !mounted) return;
    try {
      await widget.repository.saveVariantGroup(
        groupId: group?.id,
        name: draft.name,
        isRequired: draft.isRequired,
        minSelection: draft.minSelection,
        maxSelection: draft.maxSelection,
        options: draft.options,
      );
      if (!mounted) return;
      _reload();
      _showMessage(
        group == null
            ? 'Grup varian berhasil dibuat.'
            : 'Grup varian berhasil diperbarui.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Grup varian gagal disimpan: $error');
    }
  }

  Future<void> _deleteGroup(VariantGroupDefinition group) async {
    late final List<ManagedProduct> products;
    try {
      products = await widget.productsRepository.getProducts();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Produk tidak dapat diperiksa sebelum penghapusan: $error');
      return;
    }
    if (!mounted) return;
    final linkedProducts = products
        .where((product) => product.variantGroupIds.contains(group.id))
        .toList(growable: false);
    if (linkedProducts.isNotEmpty) {
      _showMessage(
        'Grup ini masih digunakan oleh ${linkedProducts.length} produk. '
        'Lepaskan grup dari produk sebelum menghapusnya.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus grup varian?'),
        content: Text(
          'Grup "${group.name}" akan dihapus permanen dari server.',
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
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteVariantGroup(group.id);
      if (!mounted) return;
      _reload();
      _showMessage('Grup varian berhasil dihapus.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Grup varian gagal dihapus: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _VariantGroupsData {
  const _VariantGroupsData({required this.groups});

  final List<VariantGroupDefinition> groups;
}
