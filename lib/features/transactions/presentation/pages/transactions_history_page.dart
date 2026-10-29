import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../bloc/transactions_history_cubit.dart';
import '../../../products/presentation/pages/product_formatters.dart';

part '../widgets/transactions_history_widgets.dart';
part '../widgets/transaction_history_cards.dart';
part '../widgets/transaction_history_shared_widgets.dart';
part '../widgets/transaction_settlement_widgets.dart';

class TransactionsHistoryPage extends StatefulWidget {
  const TransactionsHistoryPage({super.key, required this.repository});

  final CheckoutRepository repository;

  @override
  State<TransactionsHistoryPage> createState() =>
      _TransactionsHistoryPageState();
}

class _TransactionsHistoryPageState extends State<TransactionsHistoryPage> {
  var _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionsHistoryCubit(widget.repository)..load(),
      child: Builder(
        builder: (providerContext) => Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Transaksi'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: providerContext
                    .read<TransactionsHistoryCubit>()
                    .load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: BlocBuilder<TransactionsHistoryCubit, TransactionsHistoryState>(
            builder: (context, state) => switch (state) {
              TransactionsHistoryLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              TransactionsHistoryFailure() => _failure(context, state.message),
              TransactionsHistoryLoaded() => _history(context, state),
            },
          ),
        ),
      ),
    );
  }

  Future<void> _settle(
    BuildContext context,
    TransactionRecord transaction,
    TransactionsHistoryCubit cubit,
  ) async {
    try {
      final methods = (await widget.repository.getPaymentMethods())
          .where((method) => !method.isOpenBill)
          .toList(growable: false);
      if (!context.mounted) return;
      if (methods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada metode pembayaran aktif.')),
        );
        return;
      }
      final result = await showDialog<_SettlementInput>(
        context: context,
        builder: (_) =>
            _SettlementDialog(transaction: transaction, methods: methods),
      );
      if (result == null || !context.mounted) return;
      await cubit.settle(
        transaction: transaction,
        paymentMethod: result.paymentMethod,
        paidAmount: result.paidAmount,
        pin: result.pin,
      );
      if (!context.mounted) return;
      final currentState = cubit.state;
      if (currentState is TransactionsHistoryLoaded &&
          currentState.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(currentState.errorMessage!)));
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
