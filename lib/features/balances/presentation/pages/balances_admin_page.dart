import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/app_colors.dart';
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
  final _historySearchController = TextEditingController();
  String _historyQuery = '';

  @override
  void initState() {
    super.initState();
    _paymentMethods = widget.checkoutRepository.getPaymentMethods();
  }

  @override
  void dispose() {
    _historySearchController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: AppColors.dashboardBackground,
              elevation: 0,
              title: const SizedBox.shrink(),
            )
          : null,
      body: SafeArea(
        child: Column(
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
              child: RefreshIndicator(
                onRefresh: context.read<BalancesCubit>().load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    _pageHeader(context, state.balances),
                    const SizedBox(height: 24),
                    _balanceCards(context, state.balances),
                    const SizedBox(height: 24),
                    _historySection(context, state.history),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageHeader(BuildContext context, List<BalanceAccount> balances) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _openBalanceEditor(context, balances: balances),
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Sesuaikan Saldo'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Muat ulang',
              onPressed: context.read<BalancesCubit>().load,
              icon: const Icon(Icons.refresh),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                fixedSize: const Size(54, 54),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Aksi keuangan lainnya',
              onSelected: (action) {
                if (action == 'expense') {
                  _openBalanceEditor(
                    context,
                    balances: balances,
                    isExpense: true,
                  );
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'expense',
                  child: Text('Catat pengeluaran'),
                ),
              ],
              child: Container(
                height: 54,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMINISTRASI',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keuangan & Saldo',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pantau pergerakan uang tunai maupun non-tunai dan tetapkan saldo awal perusahaan.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: constraints.maxWidth >= 760
              ? Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 20),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 18), actions],
                ),
        );
      },
    );
  }

  Widget _balanceCards(BuildContext context, List<BalanceAccount> balances) {
    final totalBalance = balances.fold<num>(
      0,
      (total, account) => total + account.balance,
    );
    final cards = <Widget>[
      _TotalBalanceCard(totalBalance: totalBalance),
      ...balances.map(
        (account) => _PaymentBalanceCard(
          account: account,
          onAdjust: () => _openBalanceEditor(
            context,
            balances: balances,
            selectedPaymentMethod: account.paymentMethod,
          ),
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        const spacing = 14.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
            if (balances.isEmpty)
              SizedBox(
                width: cardWidth,
                child: const _FinanceEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  message: 'Belum ada saldo tercatat.',
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _historySection(
    BuildContext context,
    List<BalanceHistoryEntry> history,
  ) {
    final query = _historyQuery.trim().toLowerCase();
    final filteredHistory = history
        .where((entry) {
          final searchable = [
            entry.paymentMethod,
            _historyType(entry.type),
            entry.notes,
            entry.createdBy ?? '',
            entry.createdByEmail ?? '',
          ].join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final title = Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Riwayat Mutasi Saldo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                );
                final search = SizedBox(
                  width: constraints.maxWidth >= 760
                      ? 280
                      : constraints.maxWidth,
                  child: TextField(
                    controller: _historySearchController,
                    onChanged: (value) => setState(() => _historyQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Cari catatan, metode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _historyQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: () {
                                _historySearchController.clear();
                                setState(() => _historyQuery = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                );

                if (constraints.maxWidth >= 760) {
                  return Row(
                    children: [
                      Expanded(child: title),
                      search,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [title, const SizedBox(height: 12), search],
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (filteredHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: _FinanceEmptyState(
                icon: Icons.receipt_long_outlined,
                message: history.isEmpty
                    ? 'Belum ada riwayat mutasi saldo.'
                    : 'Tidak ada mutasi yang cocok dengan pencarian.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 760
                  ? Column(
                      children: [
                        for (final entry in filteredHistory)
                          _BalanceHistoryCard(entry: entry),
                      ],
                    )
                  : _historyTable(filteredHistory),
            ),
        ],
      ),
    );
  }

  Widget _historyTable(List<BalanceHistoryEntry> history) {
    const columnWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(210),
      1: FixedColumnWidth(150),
      2: FixedColumnWidth(120),
      3: FixedColumnWidth(160),
      4: FixedColumnWidth(170),
      5: FixedColumnWidth(160),
      6: FlexColumnWidth(),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1250,
        child: Table(
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFAFCFF)),
              children: [
                for (final heading in [
                  'WAKTU',
                  'METODE',
                  'JENIS',
                  'MUTASI',
                  'SALDO AKHIR',
                  'OLEH',
                  'CATATAN',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 17,
                    ),
                    child: Text(
                      heading,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
              ],
            ),
            for (final entry in history)
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                children: [
                  _historyCell(
                    entry.createdAt == null ? '—' : _dateTime(entry.createdAt!),
                  ),
                  _historyCell(_paymentMethodLabel(entry.paymentMethod)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    child: _HistoryTypeBadge(type: entry.type),
                  ),
                  _historyCell(
                    _signedAmount(entry.amount),
                    color: entry.amount >= 0
                        ? AppColors.success
                        : AppColors.danger,
                    bold: true,
                  ),
                  _historyCell(_rupiah(entry.finalBalance), bold: true),
                  _historyCell(entry.createdBy ?? entry.createdByEmail ?? '—'),
                  _historyCell(
                    entry.notes.isEmpty ? '—' : entry.notes,
                    maxLines: 2,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _historyCell(
    String text, {
    Color color = AppColors.textPrimary,
    bool bold = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    ),
  );

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
    required bool isExpense,
    List<BalanceAccount> balances = const [],
    String? selectedPaymentMethod,
  }) async {
    final initialMethod = selectedPaymentMethod != null
        ? methods
                  .where(
                    (method) =>
                        method.code.toUpperCase() ==
                        selectedPaymentMethod.toUpperCase(),
                  )
                  .firstOrNull
                  ?.code ??
              methods.first.code
        : balances.isNotEmpty
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

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.totalBalance});

  final num totalBalance;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 144),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF0F7FF), Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: const Color(0xFFCCE0FF)),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Total Keseluruhan',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.account_balance_outlined, color: Color(0xFF60A5FA)),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _rupiah(totalBalance),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF1E3A8A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _PaymentBalanceCard extends StatelessWidget {
  const _PaymentBalanceCard({required this.account, required this.onAdjust});

  final BalanceAccount account;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final code = account.paymentMethod.toUpperCase();
    final color = code == 'CASH'
        ? const Color(0xFFF59E0B)
        : const Color(0xFF94A3B8);
    return Container(
      constraints: const BoxConstraints(minHeight: 144),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_paymentMethodLabel(code)} ($code)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(_paymentIcon(code), color: color),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  _rupiah(account.balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAdjust,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text('SESUAIKAN'),
              ),
            ],
          ),
        ],
      ),
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

class _HistoryTypeBadge extends StatelessWidget {
  const _HistoryTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type.toLowerCase()) {
      'sales' || 'refund' => AppColors.primary,
      'expense' => AppColors.warning,
      'adjustment' || 'initial' => const Color(0xFF64748B),
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _historyType(type).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
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
                  helperText: widget.isExpense
                      ? 'Nominal ini akan mengurangi saldo metode yang dipilih.'
                      : 'Masukkan saldo hasil hitung fisik, bukan selisihnya.',
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

class _BalanceHistoryCard extends StatelessWidget {
  const _BalanceHistoryCard({required this.entry});

  final BalanceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.amount > 0;
    final isDebit = entry.amount < 0;
    final color = isCredit
        ? const Color(0xFF16834A)
        : isDebit
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = isCredit
        ? Icons.south_west
        : isDebit
        ? Icons.north_east
        : Icons.swap_horiz;
    final amount = isCredit
        ? _signedAmount(entry.amount)
        : isDebit
        ? _signedAmount(entry.amount)
        : _rupiah(entry.amount);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _paymentMethodLabel(entry.paymentMethod),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.createdAt == null
                          ? 'Waktu tidak tersedia'
                          : _dateTime(entry.createdAt!),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                textAlign: TextAlign.end,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HistoryTypeBadge(type: entry.type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saldo akhir ${_rupiah(entry.finalBalance)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.notes,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (entry.createdBy != null || entry.createdByEmail != null) ...[
            const SizedBox(height: 6),
            Text(
              'Oleh ${entry.createdBy ?? entry.createdByEmail}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FinanceEmptyState extends StatelessWidget {
  const _FinanceEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _historyType(String type) => switch (type) {
  'initial' => 'Saldo awal',
  'adjustment' => 'Penyesuaian',
  'sales' => 'Penjualan',
  'expense' => 'Pengeluaran',
  'refund' => 'Refund',
  _ => type,
};

String _paymentMethodLabel(String method) => switch (method.toUpperCase()) {
  'CASH' => 'Cash',
  'CARD' => 'Debit / Kredit',
  'QRIS' => 'QRIS',
  'BANK_TRANSFER' || 'TRANSFER' || 'BANK' => 'Transfer Bank',
  'OPEN_BILL' => 'Open Bill',
  _ => method,
};

IconData _paymentIcon(String method) => switch (method.toUpperCase()) {
  'CASH' => Icons.volunteer_activism_outlined,
  'BANK_TRANSFER' || 'TRANSFER' || 'BANK' => Icons.account_balance_outlined,
  _ => Icons.monetization_on_outlined,
};

String _signedAmount(num amount) =>
    '${amount > 0
        ? '+'
        : amount < 0
        ? '-'
        : ''} ${_rupiah(amount.abs())}';

String _rupiah(num amount) {
  final digits = amount.abs().toInt().toString();
  final result = StringBuffer(amount < 0 ? '- Rp ' : 'Rp ');
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
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}, '
      '${twoDigits(local.hour)}.${twoDigits(local.minute)}.'
      '${twoDigits(local.second)}';
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
