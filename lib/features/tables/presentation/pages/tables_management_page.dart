import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../../table_areas/domain/entities/table_area.dart';
import '../../../table_areas/domain/repositories/table_areas_repository.dart';
import '../../domain/entities/managed_table.dart';
import '../../domain/repositories/tables_repository.dart';
import '../bloc/tables_cubit.dart';
import '../widgets/table_dialog.dart';

class TablesManagementPage extends StatelessWidget {
  const TablesManagementPage({
    super.key,
    required this.repository,
    required this.areasRepository,
  });

  final TablesRepository repository;
  final TableAreasRepository areasRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TablesCubit(repository, areasRepository)..load(),
      child: const _TablesView(),
    );
  }
}

class _TablesView extends StatefulWidget {
  const _TablesView();

  @override
  State<_TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends State<_TablesView> {
  static const _allAreas = '';
  static const _allStatuses = '';
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedAreaId = _allAreas;
  String _selectedStatus = _allStatuses;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TablesCubit, TablesState>(
      listener: (context, state) {
        final message = switch (state) {
          TablesLoaded(errorMessage: final error?) => error,
          TablesFailure(:final message) => message,
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
          title: const Text('Tables'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<TablesCubit>().load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<TablesCubit, TablesState>(
            builder: (context, state) => switch (state) {
              TablesLoading() => const MasterDataLoadingState(),
              TablesFailure(:final message) => MasterDataErrorState(
                title: 'Daftar meja belum dapat dimuat.',
                message: message,
                onRetry: context.read<TablesCubit>().load,
              ),
              TablesLoaded(:final tables, :final areas) => _buildLoaded(
                context,
                tables,
                areas,
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    List<ManagedTable> tables,
    List<TableArea> areas,
  ) {
    final visible = tables
        .where(
          (table) =>
              (table.name.toLowerCase().contains(_query) ||
                  table.areaName.toLowerCase().contains(_query)) &&
              (_selectedAreaId.isEmpty || table.areaId == _selectedAreaId) &&
              (_selectedStatus.isEmpty || table.status == _selectedStatus),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: context.read<TablesCubit>().load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _header(context),
            const SizedBox(height: 20),
            _searchPanel(areas),
            const SizedBox(height: 20),
            if (tables.isEmpty)
              MasterDataEmptyState(
                icon: Icons.table_bar_outlined,
                title: 'Belum ada meja.',
                message: areas.isEmpty
                    ? 'Tambahkan area terlebih dahulu sebelum membuat meja.'
                    : 'Tambahkan meja untuk mengelola kapasitas dan ketersediaan.',
                onAction: areas.isEmpty
                    ? null
                    : () => _editTable(context, areas),
                actionLabel: areas.isEmpty ? null : 'Tambah Meja',
              )
            else if (visible.isEmpty)
              const MasterDataEmptyState(
                icon: Icons.search_off,
                title: 'Meja tidak ditemukan.',
                message: 'Coba kata pencarian, area, atau status lainnya.',
              )
            else
              _tablesTable(context, visible, constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => MasterDataHeader(
    title: 'Tables',
    description: 'Kelola nomor meja, kapasitas, area, dan status ketersediaan.',
    addLabel: 'Tambah Tables',
    onRefresh: () => context.read<TablesCubit>().load(),
    onAdd: () {
      final state = context.read<TablesCubit>().state;
      if (state case TablesLoaded(:final areas)) {
        if (areas.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tambahkan area terlebih dahulu sebelum membuat meja.',
              ),
            ),
          );
        } else {
          _editTable(context, areas);
        }
      }
    },
  );

  Widget _searchPanel(List<TableArea> areas) => MasterDataSearchPanel(
    controller: _searchController,
    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
    query: _query,
    hintText: 'Cari nama meja atau area...',
    trailingWidth: 340,
    trailing: Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedAreaId,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: _allAreas,
                child: Text('Semua Areas', overflow: TextOverflow.ellipsis),
              ),
              for (final area in areas)
                DropdownMenuItem(
                  value: area.id,
                  child: Text(area.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) =>
                setState(() => _selectedAreaId = value ?? _allAreas),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: _allStatuses,
                child: Text('Semua Status', overflow: TextOverflow.ellipsis),
              ),
              for (final status in const ['available', 'occupied', 'reserved'])
                DropdownMenuItem(
                  value: status,
                  child: Text(
                    _statusLabel(status),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) =>
                setState(() => _selectedStatus = value ?? _allStatuses),
          ),
        ),
      ],
    ),
  );

  Widget _tablesTable(
    BuildContext context,
    List<ManagedTable> tables,
    double availableWidth,
  ) {
    return ResponsiveDataTable(
      minWidth: availableWidth - 40,
      columns: const [
        DataColumn(label: Text('NAMA TABLES')),
        DataColumn(label: Text('AREAS')),
        DataColumn(label: Text('KAPASITAS')),
        DataColumn(label: Text('STATUS TABLES')),
        DataColumn(label: Text('STATUS AKTIF')),
        DataColumn(label: Text('AKSI')),
      ],
      rows: tables.map(_tableRow).toList(growable: false),
    );
  }

  DataRow _tableRow(ManagedTable table) => DataRow(
    cells: [
      DataCell(SizedBox(width: 190, child: Text(table.name))),
      DataCell(
        SizedBox(
          width: 130,
          child: Text(
            table.areaName.isEmpty ? 'Area tidak tersedia' : table.areaName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      DataCell(Text('${table.capacity} Kursi')),
      DataCell(_TableStatusBadge(status: table.status)),
      DataCell(MasterDataStatusBadge(isActive: table.isActive)),
      DataCell(
        MasterDataRowActions(
          onEdit: () {
            final state = context.read<TablesCubit>().state;
            if (state case TablesLoaded(:final areas)) {
              _editTable(context, areas, table);
            }
          },
          onDelete: () => _deleteTable(context, table),
        ),
      ),
    ],
  );

  Future<void> _editTable(
    BuildContext context,
    List<TableArea> areas, [
    ManagedTable? table,
  ]) async {
    final draft = await showDialog<ManagedTableDraft>(
      context: context,
      builder: (_) => TableDialog(areas: areas, table: table),
    );
    if (draft == null || !context.mounted) return;
    final success = await context.read<TablesCubit>().saveTable(
      tableId: table?.id,
      name: draft.name,
      areaId: draft.areaId,
      capacity: draft.capacity,
      status: draft.status,
      isActive: draft.isActive,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            table == null
                ? 'Meja berhasil ditambahkan.'
                : 'Meja berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteTable(BuildContext context, ManagedTable table) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus meja?',
      message: 'Meja "${table.name}" akan dihapus permanen.',
    );
    if (confirmed != true || !context.mounted) return;
    final success = await context.read<TablesCubit>().deleteTable(table.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Meja berhasil dihapus.')));
    }
  }
}

String _statusLabel(String status) => switch (status) {
  'available' => 'Tersedia',
  'occupied' => 'Terisi',
  'reserved' => 'Dipesan',
  _ => status,
};

class _TableStatusBadge extends StatelessWidget {
  const _TableStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final available = status == 'available';
    final reserved = status == 'reserved';
    final backgroundColor = available
        ? Colors.green
        : reserved
        ? Colors.orange
        : Theme.of(context).colorScheme.error;
    final foregroundColor = available
        ? Colors.green.shade800
        : reserved
        ? Colors.orange.shade800
        : Theme.of(context).colorScheme.error;
    return Chip(
      label: Text(_statusLabel(status)),
      visualDensity: VisualDensity.compact,
      backgroundColor: backgroundColor.withValues(alpha: .1),
      labelStyle: TextStyle(color: foregroundColor),
      side: BorderSide.none,
    );
  }
}
