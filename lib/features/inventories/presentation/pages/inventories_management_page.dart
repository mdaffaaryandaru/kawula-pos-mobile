import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../../../theme/app_colors.dart';
import '../../../product_units/domain/entities/product_unit.dart';
import '../../../product_units/domain/repositories/product_units_repository.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../bloc/inventories_cubit.dart';
import '../widgets/inventory_dialogs.dart';
import '../widgets/inventory_mutations_dialog.dart';

class InventoriesManagementPage extends StatefulWidget {
  const InventoriesManagementPage({
    super.key,
    required this.repository,
    required this.productUnitsRepository,
  });

  final InventoryRepository repository;
  final ProductUnitsRepository productUnitsRepository;

  @override
  State<InventoriesManagementPage> createState() =>
      _InventoriesManagementPageState();
}

class _InventoriesManagementPageState extends State<InventoriesManagementPage> {
  final _searchController = TextEditingController();
  late final Future<List<ProductUnit>> _unitsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _unitsFuture = widget.productUnitsRepository.getProductUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoriesCubit(widget.repository)..load(),
      child: BlocListener<InventoriesCubit, InventoriesState>(
        listener: (context, state) {
          final message = switch (state) {
            InventoriesLoaded(errorMessage: final message?) => message,
            InventoriesFailure(:final message) => message,
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Inventory')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  MasterDataSearchPanel(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    query: _query,
                    hintText: 'Cari nama bahan, kategori, atau deskripsi...',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: BlocBuilder<InventoriesCubit, InventoriesState>(
                      builder: (context, state) => switch (state) {
                        InventoriesLoading() => const MasterDataLoadingState(),
                        InventoriesFailure(:final message) =>
                          MasterDataErrorState(
                            title: 'Data inventory belum dapat dimuat.',
                            message: message,
                            onRetry: context.read<InventoriesCubit>().load,
                          ),
                        InventoriesLoaded(:final items) => _buildInventoryList(
                          context,
                          items,
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => MasterDataHeader(
    title: 'Bahan & persediaan',
    description: 'Pantau stok, harga beli, dan pergerakan bahan toko.',
    addLabel: 'Tambah bahan',
    onRefresh: () => context.read<InventoriesCubit>().load(),
    onAdd: () => _openForm(context),
  );

  Widget _buildInventoryList(BuildContext context, List<InventoryItem> items) {
    final visible = items
        .where((item) {
          final haystack = '${item.name} ${item.category} ${item.description}'
              .toLowerCase();
          return haystack.contains(_query);
        })
        .toList(growable: false);
    if (items.isEmpty) {
      return MasterDataEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada bahan inventory',
        message: 'Tambahkan bahan pertama untuk mulai mencatat persediaan.',
        onAction: () => _openForm(context),
        actionLabel: 'Tambah bahan',
      );
    }
    if (visible.isEmpty) {
      return const MasterDataEmptyState(
        icon: Icons.search_off,
        title: 'Bahan tidak ditemukan',
        message: 'Coba kata kunci lain.',
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return ResponsiveDataTable(
          minWidth: constraints.maxWidth,
          verticalScroll: true,
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: .45),
          ),
          columns: const [
            DataColumn(label: Text('NAMA BAHAN')),
            DataColumn(label: Text('STOK'), numeric: true),
            DataColumn(label: Text('SATUAN')),
            DataColumn(label: Text('HARGA BELI'), numeric: true),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('AKSI')),
          ],
          rows: visible.map((item) => _buildRow(context, item)).toList(),
        );
      },
    );
  }

  DataRow _buildRow(BuildContext context, InventoryItem item) {
    final lowStock = item.stock <= item.minStock;
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 210,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.category.isNotEmpty)
                  Text(
                    item.category,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
        DataCell(
          Text(
            '${_formatQuantity(item.stock)} ${item.unit.abbreviation}',
            style: TextStyle(
              color: lowStock ? Theme.of(context).colorScheme.error : null,
              fontWeight: lowStock ? FontWeight.w700 : null,
            ),
          ),
        ),
        DataCell(Text(item.unit.name)),
        DataCell(Text(_currency(item.buyPrice))),
        DataCell(MasterDataStatusBadge(isActive: item.isActive)),
        DataCell(
          MasterDataRowActions(
            onEdit: () => _openForm(context, item: item),
            onDelete: () => _confirmDelete(context, item),
            trailingActions: [
              IconButton(
                tooltip: 'Sesuaikan stok',
                onPressed: () => _adjustStock(context, item),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.swap_vert_rounded),
              ),
              IconButton(
                tooltip: 'Riwayat stok',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => InventoryMutationsDialog(
                    repository: widget.repository,
                    item: item,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.history),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, {InventoryItem? item}) async {
    try {
      final units = await _unitsFuture;
      if (!context.mounted) return;
      if (units
          .where((unit) => unit.isActive || unit.id == item?.unit.id)
          .isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Belum ada satuan aktif. Tambahkan satuan terlebih dahulu.',
            ),
          ),
        );
        return;
      }
      final draft = await showDialog<InventoryDraft>(
        context: context,
        builder: (_) => InventoryFormDialog(units: units, item: item),
      );
      if (draft == null || !context.mounted) return;
      final saved = await context.read<InventoriesCubit>().save(
        inventoryId: item?.id,
        name: draft.name,
        stock: item == null ? draft.stock : null,
        unitId: draft.unitId,
        category: draft.category,
        description: draft.description,
        buyPrice: draft.buyPrice,
        minStock: draft.minStock,
        maxStock: draft.maxStock,
        isActive: draft.isActive,
      );
      if (saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item == null
                  ? 'Bahan berhasil ditambahkan.'
                  : 'Bahan berhasil diperbarui.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Satuan gagal dimuat: $error')));
      }
    }
  }

  Future<void> _adjustStock(BuildContext context, InventoryItem item) async {
    final draft = await showDialog<StockAdjustmentDraft>(
      context: context,
      builder: (_) => StockAdjustmentDialog(item: item),
    );
    if (draft == null || !context.mounted) return;
    final adjusted = await context.read<InventoriesCubit>().adjust(
      inventoryId: item.id,
      type: draft.type,
      quantity: draft.quantity,
      notes: draft.notes,
    );
    if (adjusted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok berhasil disesuaikan.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, InventoryItem item) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus bahan?',
      message: 'Bahan "${item.name}" akan dihapus dari inventory.',
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await context.read<InventoriesCubit>().delete(item.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bahan berhasil dihapus.')));
    }
  }
}

String _formatQuantity(num value) =>
    value == value.toInt() ? value.toInt().toString() : value.toString();

String _currency(num value) {
  final digits = value.round().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp $formatted';
}
