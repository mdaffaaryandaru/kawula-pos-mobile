import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../bloc/transactions_history_cubit.dart';
import '../../../products/presentation/pages/product_formatters.dart';

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
      child: Scaffold(
        appBar: AppBar(title: const Text('Transaksi')),
        body: BlocBuilder<TransactionsHistoryCubit, TransactionsHistoryState>(
          builder: (context, state) => switch (state) {
            TransactionsHistoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TransactionsHistoryFailure() => _failure(
              context,
              state.message,
            ),
            TransactionsHistoryLoaded() => _history(context, state),
          },
        ),
      ),
    );
  }

  Widget _history(
    BuildContext context,
    TransactionsHistoryLoaded state,
  ) {
    final pending = state.transactions
        .where((transaction) => transaction.isPending)
        .toList(growable: false);
    final transactions = _selectedTab == 0 ? state.transactions : pending;
    return Column(
      children: [
        if (state.errorMessage != null)
          _ErrorBanner(message: state.errorMessage!),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text('Semua (${state.transactions.length})'),
                icon: const Icon(Icons.receipt_long),
              ),
              ButtonSegment(
                value: 1,
                label: Text('Open bill (${pending.length})'),
                icon: const Icon(Icons.pending_actions),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (selection) =>
                setState(() => _selectedTab = selection.first),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: context.read<TransactionsHistoryCubit>().load,
            child: transactions.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Text(
                          _selectedTab == 0
                              ? 'Belum ada transaksi.'
                              : 'Tidak ada open bill.',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _TransactionCard(
                        transaction: transaction,
                        onSettle: transaction.isPending
                            ? () => _settle(context, transaction)
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _failure(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Riwayat transaksi belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<TransactionsHistoryCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _settle(
    BuildContext context,
    TransactionRecord transaction,
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
        builder: (_) => _SettlementDialog(
          transaction: transaction,
          methods: methods,
        ),
      );
      if (result == null || !context.mounted) return;
      await context.read<TransactionsHistoryCubit>().settle(
        transaction: transaction,
        paymentMethod: result.paymentMethod,
        paidAmount: result.paidAmount,
        pin: result.pin,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, this.onSettle});

  final TransactionRecord transaction;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final status = transaction.status.toLowerCase();
    final statusLabel = switch (status) {
      'completed' => 'Lunas',
      'pending' => 'Open bill',
      'cancelled' => 'Dibatalkan',
      'refunded' => 'Refund',
      _ => transaction.status,
    };
    final date = transaction.createdAt;
    return Card(
      child: ExpansionTile(
        leading: Icon(
          transaction.isPending
              ? Icons.pending_actions
              : Icons.receipt_long_outlined,
        ),
        title: Text(formatRupiah(transaction.totalAmount)),
        subtitle: Text(
          '$statusLabel · ${date == null ? 'Waktu tidak tersedia' : _formatDate(date)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          for (final item in transaction.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${item.quantity} × ${item.productName}')),
                  Text(formatRupiah(item.price * item.quantity)),
                ],
              ),
            ),
          if (transaction.items.any((item) => item.notes.isNotEmpty)) ...[
            const SizedBox(height: 8),
            for (final item in transaction.items.where(
              (item) => item.notes.isNotEmpty,
            ))
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${item.productName}: ${item.notes}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 8),
          _DetailRow(label: 'Metode', value: transaction.paymentMethod),
          if (transaction.isPending)
            _DetailRow(label: 'Status', value: 'Menunggu pelunasan'),
          if (!transaction.isPending) ...[
            _DetailRow(
              label: 'Dibayar',
              value: formatRupiah(transaction.paidAmount),
            ),
            _DetailRow(
              label: 'Kembalian',
              value: formatRupiah(transaction.changeAmount),
            ),
          ],
          if (transaction.notes.isNotEmpty)
            _DetailRow(label: 'Catatan', value: transaction.notes),
          if (onSettle != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSettle,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Lunasi open bill'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}

class _SettlementInput {
  const _SettlementInput({
    required this.paymentMethod,
    required this.paidAmount,
    required this.pin,
  });

  final String paymentMethod;
  final num paidAmount;
  final String pin;
}

class _SettlementDialog extends StatefulWidget {
  const _SettlementDialog({
    required this.transaction,
    required this.methods,
  });

  final TransactionRecord transaction;
  final List<CheckoutPaymentMethod> methods;

  @override
  State<_SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<_SettlementDialog> {
  final _cashController = TextEditingController();
  final _pinController = TextEditingController();
  String? _selectedCode;
  String? _errorMessage;

  @override
  void dispose() {
    _cashController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final method = _findMethod(widget.methods, _selectedCode);
    return AlertDialog(
      title: const Text('Lunasi open bill'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Total transaksi: ${formatRupiah(widget.transaction.totalAmount)}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: method.code,
              decoration: const InputDecoration(labelText: 'Metode pembayaran'),
              items: [
                for (final paymentMethod in widget.methods)
                  DropdownMenuItem(
                    value: paymentMethod.code,
                    child: Text(paymentMethod.name),
                  ),
              ],
              onChanged: (value) => setState(() {
                _selectedCode = value;
                _errorMessage = null;
              }),
            ),
            if (method.isCash) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Uang diterima',
                  prefixText: 'Rp ',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'PIN kasir'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final pin = _pinController.text.trim();
            final paidAmount = method.isCash
                ? num.tryParse(_cashController.text.trim()) ?? 0
                : widget.transaction.totalAmount;
            if (pin.length != 4) {
              setState(() => _errorMessage = 'PIN harus terdiri dari 4 digit.');
              return;
            }
            if (method.isCash && paidAmount < widget.transaction.totalAmount) {
              setState(
                () => _errorMessage =
                    'Uang diterima kurang dari total transaksi.',
              );
              return;
            }
            Navigator.pop(
              context,
              _SettlementInput(
                paymentMethod: method.code,
                paidAmount: paidAmount,
                pin: pin,
              ),
            );
          },
          child: const Text('Konfirmasi pelunasan'),
        ),
      ],
    );
  }
}

CheckoutPaymentMethod _findMethod(
  List<CheckoutPaymentMethod> methods,
  String? selectedCode,
) {
  for (final method in methods) {
    if (method.code == selectedCode) return method;
  }
  return methods.first;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
