import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../framework/widgets/master_data_feedback.dart';
import '../../../../framework/widgets/master_data_header.dart';
import '../../../../framework/widgets/master_data_row_actions.dart';
import '../../../../framework/widgets/master_data_search_panel.dart';
import '../../../../framework/widgets/master_data_status_badge.dart';
import '../../../../framework/widgets/responsive_data_table.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_methods_repository.dart';
import '../bloc/payment_methods_cubit.dart';
import '../widgets/payment_method_dialog.dart';

class PaymentMethodsManagementPage extends StatelessWidget {
  const PaymentMethodsManagementPage({super.key, required this.repository});

  final PaymentMethodsRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PaymentMethodsCubit(repository)..load(),
    child: const _PaymentMethodsView(),
  );
}

class _PaymentMethodsView extends StatefulWidget {
  const _PaymentMethodsView();

  @override
  State<_PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends State<_PaymentMethodsView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<PaymentMethodsCubit, PaymentMethodsState>(
        listener: (context, state) {
          final message = switch (state) {
            PaymentMethodsLoaded(errorMessage: final error?) => error,
            PaymentMethodsFailure(:final message) => message,
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Metode Pembayaran')),
          body: SafeArea(
            child: BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
              builder: (context, state) => switch (state) {
                PaymentMethodsLoading() => const MasterDataLoadingState(),
                PaymentMethodsFailure(:final message) => MasterDataErrorState(
                  title: 'Metode pembayaran belum dapat dimuat.',
                  message: message,
                  onRetry: context.read<PaymentMethodsCubit>().load,
                ),
                PaymentMethodsLoaded(:final paymentMethods) => _buildLoaded(
                  context,
                  paymentMethods,
                ),
              },
            ),
          ),
        ),
      );

  Widget _buildLoaded(
    BuildContext context,
    List<PaymentMethod> paymentMethods,
  ) {
    final visible = paymentMethods
        .where(
          (method) => '${method.name} ${method.code} ${method.description}'
              .toLowerCase()
              .contains(_query),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: context.read<PaymentMethodsCubit>().load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            MasterDataHeader(
              title: 'Metode Pembayaran',
              description: 'Kelola opsi pembayaran kasir (Tunai, QRIS, Bank, Kartu, dsb).',
              addLabel: 'Tambah Metode Pembayaran',
              onRefresh: () => context.read<PaymentMethodsCubit>().load(),
              onAdd: () => _editPaymentMethod(context),
            ),
            const SizedBox(height: 20),
            MasterDataSearchPanel(
              controller: _searchController,
              query: _query,
              hintText: 'Cari nama, kode, atau deskripsi...',
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 20),
            if (paymentMethods.isEmpty)
              MasterDataEmptyState(
                icon: Icons.payments_outlined,
                title: 'Belum ada metode pembayaran.',
                message: 'Tambahkan metode untuk pilihan pembayaran di kasir.',
                actionLabel: 'Tambah Metode Pembayaran',
                onAction: () => _editPaymentMethod(context),
              )
            else if (visible.isEmpty)
              const MasterDataEmptyState(
                icon: Icons.search_off,
                title: 'Metode pembayaran tidak ditemukan.',
                message: 'Coba ubah kata pencarian.',
              )
            else
              _paymentMethodsTable(context, visible, constraints.maxWidth),
          ],
        ),
      ),
    );
  }

  Widget _paymentMethodsTable(
    BuildContext context,
    List<PaymentMethod> methods,
    double availableWidth,
  ) => ResponsiveDataTable(
    minWidth: availableWidth - 40,
    columns: const [
      DataColumn(label: Text('NAMA')),
      DataColumn(label: Text('KODE')),
      DataColumn(label: Text('DESKRIPSI')),
      DataColumn(label: Text('STATUS')),
      DataColumn(label: Text('AKSI')),
    ],
    rows: methods
        .map((method) => _paymentMethodRow(context, method))
        .toList(growable: false),
  );

  DataRow _paymentMethodRow(BuildContext context, PaymentMethod method) =>
      DataRow(
        cells: [
          DataCell(SizedBox(width: 170, child: Text(method.name))),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                method.code,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          DataCell(
            SizedBox(
              width: 350,
              child: Text(
                method.description.isEmpty ? '-' : method.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          DataCell(MasterDataStatusBadge(isActive: method.isActive)),
          DataCell(
            MasterDataRowActions(
              onEdit: () => _editPaymentMethod(context, method),
              onDelete: () => _deletePaymentMethod(context, method),
              deleteEnabled: method.code.toUpperCase() != 'CASH',
              deleteTooltip: method.code.toUpperCase() == 'CASH'
                  ? 'Metode CASH bawaan sistem tidak dapat dihapus'
                  : 'Hapus',
            ),
          ),
        ],
      );

  Future<void> _editPaymentMethod(
    BuildContext context, [
    PaymentMethod? method,
  ]) async {
    final draft = await showDialog<PaymentMethodDraft>(
      context: context,
      builder: (_) => PaymentMethodDialog(paymentMethod: method),
    );
    if (draft == null || !context.mounted) return;
    final saved = await context.read<PaymentMethodsCubit>().save(
      paymentMethodId: method?.id,
      code: draft.code,
      name: draft.name,
      description: draft.description,
      isActive: draft.isActive,
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            method == null
                ? 'Metode pembayaran berhasil ditambahkan.'
                : 'Metode pembayaran berhasil diperbarui.',
          ),
        ),
      );
    }
  }

  Future<void> _deletePaymentMethod(
    BuildContext context,
    PaymentMethod method,
  ) async {
    final confirmed = await MasterDataDeleteConfirmation.show(
      context,
      title: 'Hapus metode pembayaran?',
      message: 'Metode "${method.name}" (${method.code}) akan dihapus.',
    );
    if (!confirmed || !context.mounted) return;
    final deleted = await context.read<PaymentMethodsCubit>().delete(method.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metode pembayaran berhasil dihapus.')),
      );
    }
  }
}
