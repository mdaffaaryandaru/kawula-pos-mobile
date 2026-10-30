import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../domain/entities/outlet.dart';
import '../../domain/repositories/outlets_repository.dart';
import '../bloc/outlets_cubit.dart';
import '../widgets/outlet_dialog.dart';

class OutletsManagementPage extends StatelessWidget {
  const OutletsManagementPage({super.key, required this.repository});

  final OutletsRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OutletsCubit(repository)..load(),
      child: const _OutletsView(),
    );
  }
}

class _OutletsView extends StatefulWidget {
  const _OutletsView();

  @override
  State<_OutletsView> createState() => _OutletsViewState();
}

class _OutletsViewState extends State<_OutletsView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OutletsCubit, OutletsState>(
      listener: (context, state) {
        final message = switch (state) {
          OutletsLoaded(errorMessage: final error?) => error,
          OutletsFailure(:final message) => message,
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
          title: const Text('Outlets'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () => context.read<OutletsCubit>().load(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<OutletsCubit, OutletsState>(
            builder: (context, state) => switch (state) {
              OutletsLoading() => const MasterDataLoadingState(),
              OutletsFailure(:final message) => MasterDataErrorState(
                title: 'Daftar outlet belum dapat dimuat.',
                message: message,
                onRetry: context.read<OutletsCubit>().load,
              ),
              OutletsLoaded(:final outlets) => _buildLoaded(context, outlets),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<Outlet> outlets) {
    final visible = outlets
        .where(
          (outlet) =>
              '${outlet.name} ${outlet.code} ${outlet.address} ${outlet.phone}'
                  .toLowerCase()
                  .contains(_query),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: context.read<OutletsCubit>().load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _header(context),
            const SizedBox(height: 20),
            _searchPanel(),
            const SizedBox(height: 20),
            if (outlets.isEmpty)
              MasterDataEmptyState(
                icon: Icons.storefront_outlined,
                title: 'Belum ada outlet.',
                message: 'Tambahkan outlet atau cabang operasional cafe.',
                onAction: () => _editOutlet(context),
                actionLabel: 'Tambah Outlet',
              )
            else if (visible.isEmpty)
              const MasterDataEmptyState(
                icon: Icons.search_off,
                title: 'Outlet tidak ditemukan.',
                message: 'Coba kata pencarian lainnya.',
              )
            else
              _outletsTable(context, visible, constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => MasterDataHeader(
    title: 'Outlets',
    description: 'Kelola outlet/cabang operasional cafe.',
    addLabel: 'Tambah Outlet',
    onRefresh: () => context.read<OutletsCubit>().load(),
    onAdd: () => _editOutlet(context),
  );

  Widget _searchPanel() => MasterDataSearchPanel(
    controller: _searchController,
    onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
    query: _query,
    hintText: 'Cari nama, kode, alamat, atau telepon...',
  );

  Widget _outletsTable(
    BuildContext context,
    List<Outlet> outlets,
    double availableWidth,
  ) {
    return ResponsiveDataTable(
      minWidth: availableWidth - 40,
      columns: const [
        DataColumn(label: Text('NAMA')),
        DataColumn(label: Text('KODE')),
        DataColumn(label: Text('ALAMAT')),
        DataColumn(label: Text('TELEPON')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('AKSI')),
      ],
      rows: outlets.map(_outletRow).toList(growable: false),
    );
  }

  DataRow _outletRow(Outlet outlet) => DataRow(
    cells: [
      DataCell(SizedBox(width: 190, child: Text(outlet.name))),
      DataCell(
        SizedBox(
          width: 140,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(outlet.code),
              visualDensity: VisualDensity.compact,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              side: BorderSide.none,
            ),
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 230,
          child: Text(
            outlet.address.isEmpty ? '-' : outlet.address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(
        SizedBox(
          width: 150,
          child: Text(outlet.phone.isEmpty ? '-' : outlet.phone),
        ),
      ),
      DataCell(MasterDataStatusBadge(isActive: outlet.isActive)),
      DataCell(
        MasterDataRowActions(
          onEdit: () => _editOutlet(context, outlet),
          onDelete: () => _deleteOutlet(context, outlet),
        ),
      ),
    ],
  );

  Future<void> _editOutlet(BuildContext context, [Outlet? outlet]) async {
    final draft = await showDialog<OutletDraft>(
      context: context,
      builder: (_) => OutletDialog(outlet: outlet),
    );
    if (draft == null || !context.mounted) return;
    final success = await context.read<OutletsCubit>().saveOutlet(
      outletId: outlet?.id,
      name: draft.name,
      code: draft.code,
      address: draft.address,
      phone: draft.phone,
      isActive: draft.isActive,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            outlet == null
                ? 'Outlet berhasil ditambahkan.'
                : 'Outlet berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteOutlet(BuildContext context, Outlet outlet) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus outlet?',
      message: 'Outlet "${outlet.name}" akan dihapus permanen.',
    );
    if (confirmed != true || !context.mounted) return;
    final success = await context.read<OutletsCubit>().deleteOutlet(outlet.id);
    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Outlet berhasil dihapus.')));
    }
  }
}
