import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../domain/entities/product_unit.dart';
import '../../domain/repositories/product_units_repository.dart';
import '../bloc/product_units_cubit.dart';
import '../widgets/product_unit_dialog.dart';

class ProductUnitsManagementPage extends StatelessWidget {
  const ProductUnitsManagementPage({super.key, required this.repository});

  final ProductUnitsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductUnitsCubit(repository)..load(),
      child: const _ProductUnitsView(),
    );
  }
}

class _ProductUnitsView extends StatefulWidget {
  const _ProductUnitsView();

  @override
  State<_ProductUnitsView> createState() => _ProductUnitsViewState();
}

class _ProductUnitsViewState extends State<_ProductUnitsView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductUnitsCubit, ProductUnitsState>(
      listener: (context, state) {
        final message = switch (state) {
          ProductUnitsLoaded(errorMessage: final error?) => error,
          ProductUnitsFailure(:final message) => message,
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
          title: const Text('Product Units'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<ProductUnitsCubit>().load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<ProductUnitsCubit, ProductUnitsState>(
            builder: (context, state) => switch (state) {
              ProductUnitsLoading() => const MasterDataLoadingState(),
              ProductUnitsFailure(:final message) => MasterDataErrorState(
                title: 'Daftar satuan belum dapat dimuat.',
                message: message,
                onRetry: context.read<ProductUnitsCubit>().load,
              ),
              ProductUnitsLoaded(:final units) => _buildLoaded(context, units),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<ProductUnit> units) {
    final visible = units
        .where(
          (unit) => '${unit.name} ${unit.abbreviation} ${unit.description}'
              .toLowerCase()
              .contains(_query),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: context.read<ProductUnitsCubit>().load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _header(context),
              const SizedBox(height: 20),
              _searchPanel(),
              const SizedBox(height: 20),
              if (units.isEmpty)
                MasterDataEmptyState(
                  icon: Icons.straighten_outlined,
                  title: 'Belum ada satuan produk.',
                  message: 'Tambahkan satuan untuk digunakan pada inventaris dan POS.',
                  onAction: () => _editUnit(context),
                  actionLabel: 'Tambah Unit',
                )
              else if (visible.isEmpty)
                const MasterDataEmptyState(
                  icon: Icons.search_off,
                  title: 'Satuan tidak ditemukan.',
                  message: 'Coba kata pencarian lainnya.',
                )
              else
                _unitsTable(context, visible, constraints.maxWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return MasterDataHeader(
      title: 'Product Units',
      description: 'Kelola satuan produk untuk kebutuhan inventaris & POS.',
      addLabel: 'Tambah Unit',
      onRefresh: () => context.read<ProductUnitsCubit>().load(),
      onAdd: () => _editUnit(context),
    );
  }

  Widget _searchPanel() => MasterDataSearchPanel(
    controller: _searchController,
    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
    query: _query,
    hintText: 'Cari nama, singkatan, atau deskripsi...',
  );

  Widget _unitsTable(
    BuildContext context,
    List<ProductUnit> units,
    double availableWidth,
  ) {
    return ResponsiveDataTable(
      minWidth: availableWidth - 40,
      columns: const [
        DataColumn(label: Text('NAMA')),
        DataColumn(label: Text('SINGKATAN')),
        DataColumn(label: Text('DESKRIPSI')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('AKSI')),
      ],
      rows: units.map(_unitRow).toList(growable: false),
    );
  }

  DataRow _unitRow(ProductUnit unit) => DataRow(
    cells: [
      DataCell(SizedBox(width: 160, child: Text(unit.name))),
      DataCell(
        SizedBox(
          width: 180,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(unit.abbreviation),
              visualDensity: VisualDensity.compact,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer
                  .withValues(alpha: .5),
              side: BorderSide.none,
            ),
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 380,
          child: Text(
            unit.description.isEmpty ? '-' : unit.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(MasterDataStatusBadge(isActive: unit.isActive)),
      DataCell(
        MasterDataRowActions(
          onEdit: () => _editUnit(context, unit: unit),
          onDelete: () => _confirmDelete(context, unit),
        ),
      ),
    ],
  );

  Future<void> _editUnit(BuildContext context, {ProductUnit? unit}) async {
    final draft = await showDialog<ProductUnitDraft>(
      context: context,
      builder: (_) => ProductUnitDialog(unit: unit),
    );
    if (draft == null || !context.mounted) return;
    final saved = await context.read<ProductUnitsCubit>().save(
      unitId: unit?.id,
      name: draft.name,
      abbreviation: draft.abbreviation,
      description: draft.description,
      isActive: draft.isActive,
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            unit == null
                ? 'Satuan berhasil ditambahkan.'
                : 'Satuan berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, ProductUnit unit) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus satuan?',
      message: 'Satuan "${unit.name}" (${unit.abbreviation}) akan dihapus.',
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await context.read<ProductUnitsCubit>().delete(unit.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satuan ${unit.name} berhasil dihapus.')),
      );
    }
  }

}
