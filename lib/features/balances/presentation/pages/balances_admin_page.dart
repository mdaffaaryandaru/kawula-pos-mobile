import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../transactions/domain/entities/checkout.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../domain/entities/balance.dart';
import '../../domain/repositories/balances_repository.dart';
import '../bloc/balances_cubit.dart';

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Keuangan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Saldo'),
              Tab(text: 'Riwayat'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: context.read<BalancesCubit>().load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            if (state.errorMessage != null)
              MaterialBanner(
                content: Text(state.errorMessage!),
                actions: [
                  TextButton(
                    onPressed: context.read<BalancesCubit>().load,
                    child: const Text('Muat ulang'),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _balancesList(context, state.balances),
                  _historyList(context, state.history),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FutureBuilder<List<CheckoutPaymentMethod>>(
          future: _paymentMethods,
          builder: (context, snapshot) {
            final methods = snapshot.data
                ?.where((method) => !method.isOpenBill)
                .toList(growable: false);
            return PopupMenuButton<String>(
              tooltip: 'Aksi keuangan',
              icon: const Icon(Icons.add),
              onSelected: (action) {
                if (!snapshot.hasData || methods == null || methods.isEmpty) {
                  _showMessage(
                    context,
                    snapshot.hasError
                        ? 'Metode pembayaran gagal dimuat: ${snapshot.error}'
                        : 'Tidak ada metode pembayaran aktif.',
                  );
                  return;
                }
                if (action == 'expense') {
                  _editBalance(context, methods: methods, isExpense: true);
                } else {
                  _editBalance(
                    context,
                    methods: methods,
                    balances: state.balances,
                    isExpense: false,
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'expense',
                  child: Text('Catat pengeluaran'),
                ),
                PopupMenuItem(value: 'adjust', child: Text('Sesuaikan saldo')),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _balancesList(BuildContext context, List<BalanceAccount> balances) {
    return RefreshIndicator(
      onRefresh: context.read<BalancesCubit>().load,
      child: balances.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text('Belum ada saldo tercatat.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: balances.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final account = balances[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    title: Text(account.paymentMethod),
                    subtitle: const Text('Saldo sistem'),
                    trailing: Text(
                      _rupiah(account.balance),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _historyList(BuildContext context, List<BalanceHistoryEntry> history) {
    return RefreshIndicator(
      onRefresh: context.read<BalancesCubit>().load,
      child: history.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 100),
                Center(child: Text('Belum ada riwayat mutasi saldo.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = history[index];
                final isCredit = entry.amount >= 0;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      isCredit ? Icons.south_west : Icons.north_east,
                      color: isCredit ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      '${_historyType(entry.type)} · ${entry.paymentMethod}',
                    ),
                    subtitle: Text(
                      [
                        entry.notes,
                        if (entry.createdBy != null) 'Oleh ${entry.createdBy}',
                        if (entry.createdAt != null)
                          _dateTime(entry.createdAt!),
                        'Saldo akhir ${_rupiah(entry.finalBalance)}',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      '${isCredit ? '+' : ''}${_rupiah(entry.amount)}',
                      style: TextStyle(
                        color: isCredit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editBalance(
    BuildContext context, {
    required List<CheckoutPaymentMethod> methods,
    required bool isExpense,
    List<BalanceAccount> balances = const [],
  }) async {
    final initialMethod = balances.isNotEmpty
        ? methods
                  .where(
                    (method) =>
                        method.code.toUpperCase() ==
                        balances.first.paymentMethod.toUpperCase(),
                  )
                  .firstOrNull
                  ?.code ??
              methods.first.code
        : methods.first.code;
    final draft = await showDialog<_BalanceDraft>(
      context: context,
      builder: (_) => _BalanceDialog(
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
    _showMessage(
      context,
      success
          ? isExpense
                ? 'Pengeluaran berhasil dicatat.'
                : 'Saldo berhasil disesuaikan.'
          : currentState is BalancesLoaded
          ? currentState.errorMessage ?? 'Operasi tidak berhasil.'
          : currentState is BalancesFailure
          ? currentState.message
          : 'Operasi tidak berhasil.',
    );
  }
}

class _BalancesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BalancesAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('Keuangan'));
}

class _BalanceDialog extends StatefulWidget {
  const _BalanceDialog({
    required this.methods,
    required this.balances,
    required this.initialMethod,
    required this.isExpense,
  });

  final List<CheckoutPaymentMethod> methods;
  final List<BalanceAccount> balances;
  final String initialMethod;
  final bool isExpense;

  @override
  State<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<_BalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.initialMethod;
    if (!widget.isExpense) {
      final balance = widget.balances
          .where(
            (item) =>
                item.paymentMethod.toUpperCase() ==
                _paymentMethod.toUpperCase(),
          )
          .firstOrNull
          ?.balance;
      if (balance != null) _amountController.text = balance.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isExpense ? 'Catat pengeluaran' : 'Sesuaikan saldo';
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Metode pembayaran',
                ),
                items: widget.methods
                    .map(
                      (method) => DropdownMenuItem(
                        value: method.code,
                        child: Text(method.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _paymentMethod = value;
                    if (!widget.isExpense) {
                      final balance = widget.balances
                          .where(
                            (item) =>
                                item.paymentMethod.toUpperCase() ==
                                value.toUpperCase(),
                          )
                          .firstOrNull
                          ?.balance;
                      _amountController.text = balance?.toString() ?? '0';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: widget.isExpense
                      ? 'Nominal pengeluaran'
                      : 'Saldo aktual',
                  prefixText: 'Rp ',
                ),
                validator: (value) {
                  final amount = num.tryParse(value ?? '');
                  if (amount == null || !amount.isFinite || amount < 0) {
                    return 'Masukkan nominal yang valid.';
                  }
                  if (widget.isExpense && amount == 0) {
                    return 'Pengeluaran harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Catatan'),
                maxLines: 2,
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Catatan wajib diisi.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _BalanceDraft(
                paymentMethod: _paymentMethod,
                amount: num.parse(_amountController.text),
                notes: _notesController.text.trim(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _BalanceDraft {
  const _BalanceDraft({
    required this.paymentMethod,
    required this.amount,
    required this.notes,
  });

  final String paymentMethod;
  final num amount;
  final String notes;
}

String _historyType(String type) => switch (type) {
  'initial' => 'Saldo awal',
  'adjustment' => 'Penyesuaian',
  'sales' => 'Penjualan',
  'expense' => 'Pengeluaran',
  'refund' => 'Refund',
  _ => type,
};

String _rupiah(num amount) {
  final digits = amount.abs().toInt().toString();
  final result = StringBuffer('Rp ');
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  if (amount % 1 != 0) {
    result
      ..write(',')
      ..write((amount.abs() % 1).toStringAsFixed(2).substring(2));
  }
  return result.toString();
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
