import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../../outlets/domain/entities/outlet.dart';
import '../../../outlets/domain/repositories/outlets_repository.dart';
import '../../domain/entities/table_area.dart';
import '../../domain/repositories/table_areas_repository.dart';
import '../bloc/table_areas_cubit.dart';
import '../widgets/table_area_dialog.dart';

class TableAreasManagementPage extends StatelessWidget {
  const TableAreasManagementPage({
    super.key,
    required this.repository,
    required this.outletsRepository,
  });

  final TableAreasRepository repository;
  final OutletsRepository outletsRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TableAreasCubit(repository, outletsRepository)..load(),
      child: const _TableAreasView(),
    );
  }
}

class _TableAreasView extends StatefulWidget {
  const _TableAreasView();

  @override
  State<_TableAreasView> createState() => _TableAreasViewState();
}

class _TableAreasViewState extends State<_TableAreasView> {
  static const _allOutlets = '';
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedOutletId = _allOutlets;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TableAreasCubit, TableAreasState>(
      listener: (context, state) {
        final message = switch (state) {
          TableAreasLoaded(errorMessage: final error?) => error,
          TableAreasFailure(:final message) => message,
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
          title: const Text('Areas'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<TableAreasCubit>().load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<TableAreasCubit, TableAreasState>(
            builder: (context, state) => switch (state) {
              TableAreasLoading() => const MasterDataLoadingState(),
              TableAreasFailure(:final message) => MasterDataErrorState(
                title: 'Daftar area belum dapat dimuat.',
                message: message,
                onRetry: context.read<TableAreasCubit>().load,
              ),
              TableAreasLoaded(:final areas, :final outlets) => _buildLoaded(
                context,
                areas,
                outlets,
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    List<TableArea> areas,
    List<Outlet> outlets,
  ) {
    final visible = areas
        .where(
          (area) =>
              (area.name.toLowerCase().contains(_query) ||
                  area.description.toLowerCase().contains(_query) ||
                  area.outletName.toLowerCase().contains(_query)) &&
              (_selectedOutletId.isEmpty || area.outletId == _selectedOutletId),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: context.read<TableAreasCubit>().load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _header(context),
            const SizedBox(height: 20),
            _searchPanel(outlets),
            const SizedBox(height: 20),
            if (areas.isEmpty)
              MasterDataEmptyState(
                icon: Icons.table_bar_outlined,
                title: 'Belum ada area.',
                message: 'Tambahkan area atau zona meja pada outlet.',
                onAction: outlets.isEmpty
                    ? null
                    : () => _editArea(context, outlets),
                actionLabel: outlets.isEmpty ? null : 'Tambah Area',
              )
            else if (visible.isEmpty)
              const MasterDataEmptyState(
                icon: Icons.search_off,
                title: 'Area tidak ditemukan.',
                message: 'Coba kata pencarian atau outlet lainnya.',
              )
            else
              _areasTable(context, visible, constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => MasterDataHeader(
    title: 'Areas',
    description: 'Kelola area/zona meja pada setiap outlet.',
    addLabel: 'Tambah Areas',
    onRefresh: () => context.read<TableAreasCubit>().load(),
    onAdd: () {
      final state = context.read<TableAreasCubit>().state;
      if (state case TableAreasLoaded(:final outlets)) {
        _editArea(context, outlets);
      }
    },
  );

  Widget _searchPanel(List<Outlet> outlets) => MasterDataSearchPanel(
    controller: _searchController,
    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
    query: _query,
    hintText: 'Cari nama area, deskripsi, atau outlet...',
    trailing: DropdownButtonFormField<String>(
      initialValue: _selectedOutletId,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: _allOutlets, child: Text('Semua Outlet')),
        for (final outlet in outlets)
          DropdownMenuItem(
            value: outlet.id,
            child: Text(outlet.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) =>
          setState(() => _selectedOutletId = value ?? _allOutlets),
    ),
  );

  Widget _areasTable(
    BuildContext context,
    List<TableArea> areas,
    double availableWidth,
  ) {
    return ResponsiveDataTable(
      minWidth: availableWidth - 40,
      columns: const [
        DataColumn(label: Text('NAMA AREAS')),
        DataColumn(label: Text('OUTLETS')),
        DataColumn(label: Text('DESKRIPSI')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('AKSI')),
      ],
      rows: areas.map(_areaRow).toList(growable: false),
    );
  }

  DataRow _areaRow(TableArea area) => DataRow(
    cells: [
      DataCell(SizedBox(width: 210, child: Text(area.name))),
      DataCell(
        SizedBox(
          width: 260,
          child: Text(
            area.outletName.isEmpty ? 'Outlet tidak tersedia' : area.outletName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 180,
          child: Text(
            area.description.isEmpty ? '-' : area.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(MasterDataStatusBadge(isActive: area.isActive)),
      DataCell(
        MasterDataRowActions(
          onEdit: () {
            final state = context.read<TableAreasCubit>().state;
            if (state case TableAreasLoaded(:final outlets)) {
              _editArea(context, outlets, area);
            }
          },
          onDelete: () => _deleteArea(context, area),
        ),
      ),
    ],
  );

  Future<void> _editArea(
    BuildContext context,
    List<Outlet> outlets, [
    TableArea? area,
  ]) async {
    final draft = await showDialog<TableAreaDraft>(
      context: context,
      builder: (_) => TableAreaDialog(outlets: outlets, area: area),
    );
    if (draft == null || !context.mounted) return;
    final success = await context.read<TableAreasCubit>().saveTableArea(
      areaId: area?.id,
      name: draft.name,
      outletId: draft.outletId,
      description: draft.description,
      isActive: draft.isActive,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            area == null
                ? 'Area berhasil ditambahkan.'
                : 'Area berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteArea(BuildContext context, TableArea area) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus area?',
      message: 'Area "${area.name}" akan dihapus permanen.',
    );
    if (confirmed != true || !context.mounted) return;
    final success = await context.read<TableAreasCubit>().deleteTableArea(
      area.id,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Area berhasil dihapus.')));
    }
  }
}
