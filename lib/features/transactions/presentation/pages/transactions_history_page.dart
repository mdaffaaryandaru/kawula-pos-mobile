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

  Widget _history(BuildContext context, TransactionsHistoryLoaded state) {
    final pending = state.transactions
        .where((transaction) => transaction.isPending)
        .toList(growable: false);
    final transactions = _selectedTab == 0 ? state.transactions : pending;
    final completedCount = state.transactions
        .where((transaction) => transaction.status.toLowerCase() == 'completed')
        .length;
    return Column(
      children: [
        if (state.errorMessage != null)
          _ErrorBanner(message: state.errorMessage!),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: const Icon(Icons.receipt_long_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.transactions.length} transaksi',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$completedCount lunas · ${pending.length} open bill',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
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
                            ? () => _settle(
                                context,
                                transaction,
                                context.read<TransactionsHistoryCubit>(),
                              )
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, this.onSettle});

  final TransactionRecord transaction;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final status = transaction.status.toLowerCase();
    final (statusLabel, statusColor, statusIcon) = switch (status) {
      'completed' => (
        'Lunas',
        const Color(0xFF16834A),
        Icons.check_circle_outline,
      ),
      'pending' => (
        'Open bill',
        const Color(0xFFC17A00),
        Icons.pending_actions,
      ),
      'cancelled' => (
        'Dibatalkan',
        Theme.of(context).colorScheme.error,
        Icons.cancel_outlined,
      ),
      'refunded' => (
        'Refund',
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.currency_exchange,
      ),
      _ => (
        transaction.status,
        Theme.of(context).colorScheme.onSurfaceVariant,
        Icons.receipt_long_outlined,
      ),
    };
    final date = transaction.createdAt;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          foregroundColor: statusColor,
          child: Icon(statusIcon),
        ),
        title: Text(
          formatRupiah(transaction.totalAmount),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _TransactionStatusChip(label: statusLabel, color: statusColor),
              Text(
                date == null ? 'Waktu tidak tersedia' : _formatDate(date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 8),
          if (transaction.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rincian item tidak disertakan pada respons transaksi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            for (final item in transaction.items) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity} × ${item.productName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(formatRupiah(item.price * item.quantity)),
                  ],
                ),
              ),
              if (item.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Catatan: ${item.notes}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          const Divider(height: 20),
          _DetailRow(label: 'No. transaksi', value: transaction.id),
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

class _TransactionStatusChip extends StatelessWidget {
  const _TransactionStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
  const _SettlementDialog({required this.transaction, required this.methods});

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
            Text(
              'Total transaksi: ${formatRupiah(widget.transaction.totalAmount)}',
            ),
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
