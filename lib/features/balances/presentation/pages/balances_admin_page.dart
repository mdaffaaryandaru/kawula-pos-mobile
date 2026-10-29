import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transactions/domain/entities/checkout.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../domain/entities/balance.dart';
import '../../domain/repositories/balances_repository.dart';
import '../bloc/balances_cubit.dart';
import '../widgets/balance_edit_dialog.dart';
import '../widgets/balances_overview.dart';

class BalancesAdminPage extends StatefulWidget {
  const BalancesAdminPage({
    super.key,
    required this.repository,
    required this.checkoutRepository,
  });

  final BalancesRepository repository;
  final CheckoutRepository checkoutRepository;

  @override
  State<BalancesAdminPage> createState() => _BalancesAdminPageState();
}

class _BalancesAdminPageState extends State<BalancesAdminPage> {
  late Future<List<CheckoutPaymentMethod>> _paymentMethods;

  @override
  void initState() {
    super.initState();
    _paymentMethods = widget.checkoutRepository.getPaymentMethods();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BalancesCubit(widget.repository)..load(),
      child: Builder(
        builder: (providerContext) => BlocBuilder<BalancesCubit, BalancesState>(
          builder: (context, state) => switch (state) {
            BalancesLoading() => const Scaffold(
              appBar: _BalancesAppBar(),
              body: Center(child: CircularProgressIndicator()),
            ),
            BalancesFailure() => Scaffold(
              appBar: const _BalancesAppBar(),
              body: _loadFailure(providerContext, state.message),
            ),
            BalancesLoaded() => _loadedPage(providerContext, state),
          },
        ),
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
              'Data keuangan belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<BalancesCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadedPage(BuildContext context, BalancesLoaded state) {
    final cubit = context.read<BalancesCubit>();
    return BalancesOverview(
      balances: state.balances,
      history: state.history,
      errorMessage: state.errorMessage,
      onRefresh: cubit.load,
      onAdjustBalance: () =>
          _openBalanceEditor(context, balances: state.balances),
      onAdjustPaymentMethod: (method) => _openBalanceEditor(
        context,
        balances: state.balances,
        selectedPaymentMethod: method,
      ),
      onRecordExpense: () => _openBalanceEditor(
        context,
        balances: state.balances,
        isExpense: true,
      ),
    );
  }

  Future<void> _openBalanceEditor(
    BuildContext context, {
    required List<BalanceAccount> balances,
    bool isExpense = false,
    String? selectedPaymentMethod,
  }) async {
    try {
      final methods = (await _paymentMethods)
          .where((method) => !method.isOpenBill)
          .toList(growable: false);
      if (!context.mounted) return;
      if (methods.isEmpty) {
        _showMessage(context, 'Tidak ada metode pembayaran aktif.');
        return;
      }
      await _editBalance(
        context,
        methods: methods,
        balances: balances,
        isExpense: isExpense,
        selectedPaymentMethod: selectedPaymentMethod,
      );
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Metode pembayaran gagal dimuat: $error');
      }
    }
  }

  Future<void> _editBalance(
    BuildContext context, {
    required List<CheckoutPaymentMethod> methods,
    required List<BalanceAccount> balances,
    required bool isExpense,
    String? selectedPaymentMethod,
  }) async {
    final initialMethod = _initialPaymentMethod(
      methods,
      balances,
      selectedPaymentMethod,
    );
    final draft = await showDialog<BalanceDraft>(
      context: context,
      builder: (_) => BalanceEditDialog(
        methods: methods,
        balances: balances,
        initialMethod: initialMethod,
        isExpense: isExpense,
      ),
    );
    if (draft == null || !context.mounted) return;

    final cubit = context.read<BalancesCubit>();
    final success = isExpense
        ? await cubit.recordExpense(
            paymentMethod: draft.paymentMethod,
            amount: draft.amount,
            notes: draft.notes,
          )
        : await cubit.adjustBalance(
            paymentMethod: draft.paymentMethod,
            actualBalance: draft.amount,
            notes: draft.notes,
          );
    if (!context.mounted) return;

    final currentState = cubit.state;
    final message = success
        ? isExpense
              ? 'Pengeluaran berhasil dicatat.'
              : 'Saldo berhasil disesuaikan.'
        : currentState is BalancesLoaded
        ? currentState.errorMessage ?? 'Operasi tidak berhasil.'
        : currentState is BalancesFailure
        ? currentState.message
        : 'Operasi tidak berhasil.';
    _showMessage(context, message);
  }

  String _initialPaymentMethod(
    List<CheckoutPaymentMethod> methods,
    List<BalanceAccount> balances,
    String? selectedPaymentMethod,
  ) {
    final preferredMethod =
        selectedPaymentMethod ??
        (balances.isEmpty ? null : balances.first.paymentMethod);
    return methods
            .where(
              (method) =>
                  method.code.toUpperCase() == preferredMethod?.toUpperCase(),
            )
            .firstOrNull
            ?.code ??
        methods.first.code;
  }
}

class _BalancesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BalancesAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Keuangan'));
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
