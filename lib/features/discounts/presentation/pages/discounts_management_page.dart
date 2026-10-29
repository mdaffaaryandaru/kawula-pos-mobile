import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../../products/presentation/widgets/product_management_helpers.dart';
import '../../domain/entities/discount_definition.dart';
import '../../domain/repositories/discounts_repository.dart';
import '../bloc/discounts_cubit.dart';
import '../widgets/discount_dialog.dart';

class DiscountsManagementPage extends StatelessWidget {
  const DiscountsManagementPage({super.key, required this.repository});

  final DiscountsRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => DiscountsCubit(repository)..load(),
    child: const _DiscountsView(),
  );
}

class _DiscountsView extends StatefulWidget {
  const _DiscountsView();

  @override
  State<_DiscountsView> createState() => _DiscountsViewState();
}

class _DiscountsViewState extends State<_DiscountsView> {
  final _searchController = TextEditingController();
  String _query = '';
  DiscountType? _typeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<DiscountsCubit, DiscountsState>(
    listener: (context, state) {
      final message = switch (state) {
        DiscountsLoaded(errorMessage: final error?) => error,
        DiscountsFailure(:final message) => message,
        _ => null,
      };
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Discounts')),
      body: SafeArea(
        child: BlocBuilder<DiscountsCubit, DiscountsState>(
          builder: (context, state) => switch (state) {
            DiscountsLoading() => const MasterDataLoadingState(),
            DiscountsFailure(:final message) => MasterDataErrorState(
              title: 'Daftar discount belum dapat dimuat.',
              message: message,
              onRetry: context.read<DiscountsCubit>().load,
            ),
            DiscountsLoaded(:final discounts) => _buildLoaded(
              context,
              discounts,
            ),
          },
        ),
      ),
    ),
  );

  Widget _buildLoaded(
    BuildContext context,
    List<DiscountDefinition> discounts,
  ) {
    final visible = discounts
        .where((discount) {
          final matchesSearch =
              '${discount.name} ${discount.description}'
                  .toLowerCase()
                  .contains(_query);
          return matchesSearch &&
              (_typeFilter == null || discount.type == _typeFilter);
        })
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: context.read<DiscountsCubit>().load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            MasterDataHeader(
              title: 'Discounts',
              description:
                  'Kelola diskon persentase dan nominal untuk menu cafe.',
              addLabel: 'Tambah Discount',
              onRefresh: () => context.read<DiscountsCubit>().load(),
              onAdd: () => _editDiscount(context),
            ),
            const SizedBox(height: 20),
            MasterDataSearchPanel(
              controller: _searchController,
              query: _query,
              hintText: 'Cari nama / deskripsi...',
              onChanged: (value) => setState(
                () => _query = value.trim().toLowerCase(),
              ),
              trailing: DropdownButtonFormField<DiscountType?>(
                initialValue: _typeFilter,
                isExpanded: true,
                decoration: const InputDecoration(filled: true),
                items: [
                  const DropdownMenuItem<DiscountType?>(
                    value: null,
                    child: Text('Semua Tipe'),
                  ),
                  ...DiscountType.values.map(
                    (type) => DropdownMenuItem<DiscountType?>(
                      value: type,
                      child: Text(type.label),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _typeFilter = value),
              ),
            ),
            const SizedBox(height: 20),
            if (discounts.isEmpty)
              MasterDataEmptyState(
                icon: Icons.percent,
                title: 'Belum ada discount.',
                message: 'Tambahkan diskon untuk diterapkan pada menu.',
                actionLabel: 'Tambah Discount',
                onAction: () => _editDiscount(context),
              )
            else if (visible.isEmpty)
              const MasterDataEmptyState(
                icon: Icons.search_off,
                title: 'Discount tidak ditemukan.',
                message: 'Coba ubah kata pencarian atau filter tipe.',
              )
            else
              _discountsTable(context, visible, constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  Widget _discountsTable(
    BuildContext context,
    List<DiscountDefinition> discounts,
    double availableWidth,
  ) => ResponsiveDataTable(
    minWidth: availableWidth - 40,
    columns: const [
      DataColumn(label: Text('NAMA')),
      DataColumn(label: Text('TIPE')),
      DataColumn(label: Text('NILAI')),
      DataColumn(label: Text('DESKRIPSI')),
      DataColumn(label: Text('STATUS')),
      DataColumn(label: Text('AKSI')),
    ],
    rows: discounts.map((discount) => _discountRow(context, discount)).toList(),
  );

  DataRow _discountRow(BuildContext context, DiscountDefinition discount) =>
      DataRow(
        cells: [
          DataCell(SizedBox(width: 190, child: Text(discount.name))),
          DataCell(
            Chip(
              label: Text(discount.type.label),
              visualDensity: VisualDensity.compact,
            ),
          ),
          DataCell(
            Text(
              discount.type == DiscountType.percentage
                  ? '${formatProductNumber(discount.value)}%'
                  : formatProductRupiah(discount.value),
            ),
          ),
          DataCell(
            SizedBox(
              width: 280,
              child: Text(
                discount.description.isEmpty ? '-' : discount.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DataCell(MasterDataStatusBadge(isActive: discount.isActive)),
          DataCell(
            MasterDataRowActions(
              onEdit: () => _editDiscount(context, discount),
              onDelete: () => _deleteDiscount(context, discount),
            ),
          ),
        ],
      );

  Future<void> _editDiscount(
    BuildContext context, [
    DiscountDefinition? discount,
  ]) async {
    final draft = await showDialog<DiscountDraft>(
      context: context,
      builder: (_) => DiscountDialog(discount: discount),
    );
    if (draft == null || !context.mounted) return;
    final saved = await context.read<DiscountsCubit>().save(
      discountId: discount?.id,
      name: draft.name,
      type: draft.type,
      value: draft.value,
      description: draft.description,
      isActive: draft.isActive,
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            discount == null
                ? 'Discount berhasil ditambahkan.'
                : 'Discount berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteDiscount(
    BuildContext context,
    DiscountDefinition discount,
  ) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus discount?',
      message: 'Discount "${discount.name}" akan dihapus.',
    );
    if (!confirmed || !context.mounted) return;
    final deleted = await context.read<DiscountsCubit>().delete(discount.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount berhasil dihapus.')),
      );
    }
  }
}
