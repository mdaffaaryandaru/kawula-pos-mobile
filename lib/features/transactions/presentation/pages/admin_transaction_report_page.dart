import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../theme/app_colors.dart';
import '../../../balances/domain/entities/balance.dart';
import '../../../balances/domain/repositories/balances_repository.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';

class AdminTransactionReportPage extends StatefulWidget {
  const AdminTransactionReportPage({
    super.key,
    required this.checkoutRepository,
    required this.balancesRepository,
  });

  final CheckoutRepository checkoutRepository;
  final BalancesRepository balancesRepository;

  @override
  State<AdminTransactionReportPage> createState() =>
      _AdminTransactionReportPageState();
}

class _AdminTransactionReportPageState
    extends State<AdminTransactionReportPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  late Future<_ReportData> _report;
  String _query = '';
  String _statusFilter = 'all';
  String _paymentFilter = 'all';

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _startDate = today;
    _endDate = today;
    _report = _loadReport();
  }

  Future<_ReportData> _loadReport() async {
    final results = await Future.wait<Object>([
      widget.checkoutRepository.getTransactions(),
      widget.balancesRepository.getHistory(),
    ]);
    return _ReportData(
      transactions: results[0] as List<TransactionRecord>,
      history: results[1] as List<BalanceHistoryEntry>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Transaksi'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refreshReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_ReportData>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ReportMessage(
              message: 'Laporan gagal dimuat: ${snapshot.error}',
              action: TextButton(
                onPressed: _refreshReport,
                child: const Text('Coba lagi'),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const _ReportMessage(
              message: 'Data laporan tidak tersedia.',
            );
          }
          return _buildReport(context, data);
        },
      ),
    );
  }

  Widget _buildReport(BuildContext context, _ReportData data) {
    final transactions = data.transactions.where(_inSelectedRange).toList()
      ..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    final expenses = data.history.where((entry) {
      return entry.type.toLowerCase() == 'expense' &&
          _dateInSelectedRange(entry.createdAt);
    }).toList();
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredTransactions = transactions.where((transaction) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          transaction.id.toLowerCase().contains(normalizedQuery) ||
          transaction.paymentMethod.toLowerCase().contains(normalizedQuery) ||
          transaction.status.toLowerCase().contains(normalizedQuery) ||
          transaction.notes.toLowerCase().contains(normalizedQuery) ||
          transaction.items.any(
            (item) => item.productName.toLowerCase().contains(normalizedQuery),
          );
      final matchesStatus =
          _statusFilter == 'all' ||
          transaction.status.toLowerCase() == _statusFilter;
      final matchesPayment =
          _paymentFilter == 'all' ||
          transaction.paymentMethod.toLowerCase() == _paymentFilter;
      return matchesQuery && matchesStatus && matchesPayment;
    }).toList();

    final completed = transactions
        .where((transaction) => transaction.status.toLowerCase() == 'completed')
        .toList();
    final pending = transactions
        .where((transaction) => transaction.status.toLowerCase() == 'pending')
        .toList();
    final cancelled = transactions
        .where((transaction) => transaction.status.toLowerCase() == 'cancelled')
        .length;
    final refunded = transactions
        .where((transaction) => transaction.status.toLowerCase() == 'refunded')
        .length;
    final sales = completed.fold<num>(
      0,
      (total, transaction) => total + transaction.totalAmount,
    );
    final openBills = pending.fold<num>(
      0,
      (total, transaction) => total + transaction.totalAmount,
    );
    final cogs = completed.fold<num>(
      0,
      (total, transaction) => total + transaction.cogs,
    );
    final expenseTotal = expenses.fold<num>(
      0,
      (total, entry) => total + entry.amount.abs(),
    );
    final serviceCharge = completed.fold<num>(
      0,
      (total, transaction) => total + transaction.serviceCharge,
    );
    final tax = completed.fold<num>(
      0,
      (total, transaction) => total + transaction.taxAmount,
    );
    final netProfit = sales - cogs - serviceCharge - tax - expenseTotal;
    final paymentMethods =
        transactions
            .map((transaction) => transaction.paymentMethod)
            .where((method) => method.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _ReportHeader(
          onExpense: () => _recordExpense(data.history),
          onRefresh: _refreshReport,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: columns == 1
                  ? 3.2
                  : columns == 2
                  ? 2.1
                  : 2.7,
              children: [
                _ReportMetric(
                  label: 'Omzet penjualan',
                  value: _formatRupiah(sales),
                  detail:
                      'Cash: ${_formatRupiah(_salesByMethod(completed, 'cash'))} · '
                      'Non-cash: ${_formatRupiah(_salesByMethod(completed, 'cash', exclude: true))}',
                  color: const Color(0xFF2563EB),
                  background: const Color(0xFFF0F7FF),
                ),
                _ReportMetric(
                  label: 'Laba bersih',
                  value: _formatRupiah(netProfit),
                  detail: 'Omzet - HPP - Pajak - Layanan - Biaya',
                  color: const Color(0xFF059669),
                  background: const Color(0xFFECFDF5),
                ),
                _ReportMetric(
                  label: 'Beban & operasional',
                  value: _formatRupiah(cogs + expenseTotal),
                  detail:
                      'HPP: ${_formatRupiah(cogs)} · Biaya: ${_formatRupiah(expenseTotal)}',
                  color: const Color(0xFFDC2626),
                  background: const Color(0xFFFFF1F2),
                ),
                _ReportMetric(
                  label: 'Open bill / transaksi',
                  value: _formatRupiah(openBills),
                  detail: '${transactions.length} total transaksi',
                  color: const Color(0xFFD97706),
                  background: const Color(0xFFFFFBEB),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '${completed.length} transaksi selesai · ${pending.length} open bill · '
          '$cancelled dibatalkan · $refunded refund',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 16),
        _ReportFilters(
          startDate: _startDate,
          endDate: _endDate,
          query: _query,
          status: _statusFilter,
          payment: _paymentFilter,
          paymentMethods: paymentMethods,
          resultCount: filteredTransactions.length,
          onChooseRange: _chooseDateRange,
          onQueryChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) =>
              setState(() => _statusFilter = value ?? 'all'),
          onPaymentChanged: (value) =>
              setState(() => _paymentFilter = value ?? 'all'),
          onExport: filteredTransactions.isEmpty
              ? null
              : () => _exportCsv(filteredTransactions),
        ),
        const SizedBox(height: 12),
        if (filteredTransactions.isEmpty)
          const _ReportMessage(
            message: 'Tidak ada transaksi sesuai filter yang dipilih.',
          )
        else
          _TransactionsTable(
            transactions: filteredTransactions,
            onTap: _showTransactionDetails,
          ),
        const SizedBox(height: 16),
        _ProfitSummary(
          sales: sales,
          cogs: cogs,
          serviceCharge: serviceCharge,
          tax: tax,
          expenses: expenseTotal,
          netProfit: netProfit,
          expenseEntries: expenses,
        ),
        if (cancelled > 0 || refunded > 0) ...[
          const SizedBox(height: 10),
          Text(
            '${completed.length} selesai · ${pending.length} open bill · '
            '$cancelled dibatalkan · $refunded refund',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  num _salesByMethod(
    List<TransactionRecord> completed,
    String method, {
    bool exclude = false,
  }) => completed
      .where(
        (transaction) =>
            (transaction.paymentMethod.toLowerCase() == method) != exclude,
      )
      .fold<num>(0, (total, transaction) => total + transaction.totalAmount);

  void _refreshReport() {
    setState(() {
      _report = _loadReport();
    });
  }

  Future<void> _recordExpense(List<BalanceHistoryEntry> history) async {
    final methods = history
        .map((entry) => entry.paymentMethod)
        .where((method) => method.isNotEmpty)
        .toSet();
    methods.add('CASH');
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => _RecordExpenseDialog(
        paymentMethods: methods.toList()..sort(),
        repository: widget.balancesRepository,
      ),
    );
    if (!mounted || success != true) return;
    _refreshReport();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Biaya berhasil dicatat.')));
  }

  Future<void> _chooseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (!mounted || range == null) return;
    setState(() {
      _startDate = _dateOnly(range.start);
      _endDate = _dateOnly(range.end);
    });
  }

  Future<void> _exportCsv(List<TransactionRecord> transactions) async {
    final rows = <List<String>>[
      [
        'ID',
        'Tanggal',
        'Status',
        'Metode pembayaran',
        'Total',
        'HPP',
        'Refund',
        'Produk',
      ],
      ...transactions.map(
        (transaction) => [
          transaction.id,
          transaction.createdAt?.toIso8601String() ?? '',
          transaction.status,
          transaction.paymentMethod,
          transaction.totalAmount.toString(),
          transaction.cogs.toString(),
          transaction.refundAmount.toString(),
          transaction.items.map((item) => item.productName).join('; '),
        ],
      ),
    ];
    final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    final fileName =
        'laporan-transaksi-${_fileDate(_startDate)}-'
        '${_fileDate(_endDate)}.csv';
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Laporan transaksi Kawula POS',
          files: [
            XFile.fromData(
              Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]),
              mimeType: 'text/csv',
              name: fileName,
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV tidak dapat dibagikan: $error')),
      );
    }
  }

  void _showTransactionDetails(TransactionRecord transaction) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail transaksi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('ID: ${transaction.id}'),
              Text('Status: ${_statusLabel(transaction.status)}'),
              Text('Tanggal: ${_formatDateTime(transaction.createdAt)}'),
              if (transaction.outletName.isNotEmpty)
                Text('Outlet: ${transaction.outletName}'),
              if (transaction.cashierName.isNotEmpty)
                Text('Kasir: ${transaction.cashierName}'),
              if (transaction.memberName.isNotEmpty)
                Text('Member: ${transaction.memberName}'),
              Text('Pembayaran: ${transaction.paymentMethod}'),
              Text('Total: ${_formatRupiah(transaction.totalAmount)}'),
              if (transaction.taxAmount > 0)
                Text('Pajak: ${_formatRupiah(transaction.taxAmount)}'),
              if (transaction.serviceCharge > 0)
                Text(
                  'Service charge: ${_formatRupiah(transaction.serviceCharge)}',
                ),
              if (transaction.discountAmount > 0)
                Text('Diskon: ${_formatRupiah(transaction.discountAmount)}'),
              if (transaction.refundAmount > 0)
                Text('Refund: ${_formatRupiah(transaction.refundAmount)}'),
              const SizedBox(height: 8),
              ...transaction.items.map(
                (item) => Text(
                  '${item.quantity} × ${item.productName} · '
                  '${_formatRupiah(item.price)}',
                ),
              ),
              if (transaction.notes.isNotEmpty)
                Text('Catatan: ${transaction.notes}'),
            ],
          ),
        ),
      ),
    );
  }

  bool _inSelectedRange(TransactionRecord transaction) =>
      _dateInSelectedRange(transaction.createdAt);

  bool _dateInSelectedRange(DateTime? date) {
    if (date == null) return false;
    final day = _dateOnly(date.toLocal());
    return !day.isBefore(_startDate) && !day.isAfter(_endDate);
  }
}

class _ReportData {
  const _ReportData({required this.transactions, required this.history});

  final List<TransactionRecord> transactions;
  final List<BalanceHistoryEntry> history;
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.onExpense, required this.onRefresh});

  final VoidCallback onExpense;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onExpense,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Catat Biaya'),
            ),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh'),
            ),
          ],
        );
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'L A P O R A N',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Transaksi Masuk',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Default menampilkan transaksi hari ini, termasuk penjualan, open bill, dan pembatalan.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        );
        if (constraints.maxWidth >= 700) {
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 14),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [title, const SizedBox(height: 14), actions],
        );
      },
    ),
  );
}

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.startDate,
    required this.endDate,
    required this.query,
    required this.status,
    required this.payment,
    required this.paymentMethods,
    required this.resultCount,
    required this.onChooseRange,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onPaymentChanged,
    required this.onExport,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String query;
  final String status;
  final String payment;
  final List<String> paymentMethods;
  final int resultCount;
  final VoidCallback onChooseRange;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPaymentChanged;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Cari ID, nama produk, atau pembayaran...',
            prefixIcon: const Icon(Icons.search_rounded, size: 19),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: () => onQueryChanged(''),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            filled: true,
            fillColor: AppColors.dashboardBackground,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
        );
        final date = OutlinedButton.icon(
          onPressed: onChooseRange,
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(
            '${_formatDate(startDate)} – ${_formatDate(endDate)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
        final statusField = _filterDropdown(
          value: status,
          label: 'Semua Status',
          options: const [
            ('all', 'Semua Status'),
            ('completed', 'Selesai'),
            ('pending', 'Open bill'),
            ('cancelled', 'Dibatalkan'),
            ('refunded', 'Refund'),
          ],
          onChanged: onStatusChanged,
        );
        final paymentField = _filterDropdown(
          value: payment,
          label: 'Semua Pembayaran',
          options: [
            const ('all', 'Semua Pembayaran'),
            if (payment != 'all' &&
                !paymentMethods.any(
                  (method) => method.toLowerCase() == payment,
                ))
              (payment, payment),
            ...paymentMethods.map((method) => (method.toLowerCase(), method)),
          ],
          onChanged: onPaymentChanged,
        );
        final export = OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined, size: 17),
          label: const Text('CSV'),
        );

        if (constraints.maxWidth >= 950) {
          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 8),
              SizedBox(width: 180, child: date),
              const SizedBox(width: 8),
              Expanded(child: statusField),
              const SizedBox(width: 8),
              Expanded(child: paymentField),
              const SizedBox(width: 8),
              export,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: 190, child: date),
                SizedBox(width: 170, child: statusField),
                SizedBox(width: 190, child: paymentField),
                export,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$resultCount transaksi ditemukan',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _filterDropdown({
    required String value,
    required String label,
    required List<(String, String)> options,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      filled: true,
      fillColor: AppColors.dashboardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
    ),
    items: options
        .map(
          (option) => DropdownMenuItem(
            value: option.$1,
            child: Text(option.$2, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(growable: false),
    onChanged: onChanged,
  );
}

class _TransactionsTable extends StatelessWidget {
  const _TransactionsTable({required this.transactions, required this.onTap});

  final List<TransactionRecord> transactions;
  final ValueChanged<TransactionRecord> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 760) {
        return Column(
          children: transactions
              .map((transaction) => _transactionCard(context, transaction))
              .toList(growable: false),
        );
      }
      final header = Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w800,
        letterSpacing: .6,
      );
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(17),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFC)),
            horizontalMargin: 16,
            columnSpacing: 22,
            columns: [
              DataColumn(label: Text('WAKTU & ID', style: header)),
              DataColumn(label: Text('OUTLET', style: header)),
              DataColumn(label: Text('KASIR & MEMBER', style: header)),
              DataColumn(label: Text('ITEM', style: header)),
              DataColumn(label: Text('METODE & TOTAL', style: header)),
              DataColumn(label: Text('STATUS', style: header)),
              DataColumn(label: Text('AKSI', style: header)),
            ],
            rows: transactions
                .map(
                  (transaction) => DataRow(
                    onSelectChanged: (_) => onTap(transaction),
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 125,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(transaction.createdAt),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                transaction.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 90,
                          child: Text(
                            transaction.outletName.isEmpty
                                ? '—'
                                : transaction.outletName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 110,
                          child: Text(
                            'Kasir: ${transaction.cashierName.isEmpty ? '—' : transaction.cashierName}\n'
                            'Member: ${transaction.memberName.isEmpty ? '—' : transaction.memberName}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${transaction.items.fold<int>(0, (total, item) => total + item.quantity)} Pcs',
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 118,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatRupiah(transaction.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                transaction.paymentMethod,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(_StatusBadge(status: transaction.status)),
                      DataCell(
                        OutlinedButton.icon(
                          onPressed: () => onTap(transaction),
                          icon: const Icon(Icons.visibility_outlined, size: 15),
                          label: const Text('Detail'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
    },
  );

  Widget _transactionCard(
    BuildContext context,
    TransactionRecord transaction,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap(transaction),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(transaction.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                _StatusBadge(status: transaction.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.items.isEmpty
                        ? 'Transaksi ${transaction.id}'
                        : transaction.items
                              .map((item) => item.productName)
                              .join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _formatRupiah(transaction.totalAmount),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${transaction.paymentMethod} · ${transaction.items.fold<int>(0, (total, item) => total + item.quantity)} item',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (transaction.outletName.isNotEmpty ||
                transaction.cashierName.isNotEmpty ||
                transaction.memberName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (transaction.outletName.isNotEmpty) transaction.outletName,
                  if (transaction.cashierName.isNotEmpty)
                    'Kasir: ${transaction.cashierName}',
                  if (transaction.memberName.isNotEmpty)
                    'Member: ${transaction.memberName}',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              transaction.id,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'completed' => const Color(0xFF059669),
      'pending' => const Color(0xFFD97706),
      'refunded' => const Color(0xFF7C3AED),
      'cancelled' => const Color(0xFFDC2626),
      _ => AppColors.textSecondary,
    };
    final background = switch (normalized) {
      'completed' => const Color(0xFFD1FAE5),
      'pending' => const Color(0xFFFEF3C7),
      'refunded' => const Color(0xFFEDE9FE),
      'cancelled' => const Color(0xFFFEE2E2),
      _ => const Color(0xFFF1F5F9),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfitSummary extends StatelessWidget {
  const _ProfitSummary({
    required this.sales,
    required this.cogs,
    required this.serviceCharge,
    required this.tax,
    required this.expenses,
    required this.netProfit,
    required this.expenseEntries,
  });

  final num sales;
  final num cogs;
  final num serviceCharge;
  final num tax;
  final num expenses;
  final num netProfit;
  final List<BalanceHistoryEntry> expenseEntries;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rincian Laba Bersih',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              'Omzet − HPP − Layanan − Pajak − Biaya',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ProfitLine(label: 'Omzet Penjualan (Lunas)', amount: sales),
        _ProfitLine(label: 'HPP / Modal Bahan', amount: -cogs),
        _ProfitLine(label: 'Service Charge', amount: -serviceCharge),
        _ProfitLine(label: 'Pajak (PPN)', amount: -tax),
        _ProfitLine(label: 'Biaya Operasional', amount: -expenses),
        const Divider(height: 22),
        _ProfitLine(label: 'Laba Bersih', amount: netProfit, emphasize: true),
        if (expenseEntries.isNotEmpty) ...[
          const Divider(height: 22),
          const Text(
            'BIAYA OPERASIONAL PERIODE INI',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 5),
          ...expenseEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.notes.isEmpty ? 'Biaya operasional' : entry.notes} · '
                      '${entry.paymentMethod} · ${_formatDateTime(entry.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    '-${_formatRupiah(entry.amount.abs())}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProfitLine extends StatelessWidget {
  const _ProfitLine({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final num amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasize ? AppColors.success : AppColors.textSecondary,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.normal,
              fontSize: emphasize ? 14 : 12,
            ),
          ),
        ),
        Text(
          _formatRupiah(amount),
          style: TextStyle(
            color: amount < 0
                ? AppColors.danger
                : emphasize
                ? AppColors.success
                : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: emphasize ? 14 : 12,
          ),
        ),
      ],
    ),
  );
}

class _RecordExpenseDialog extends StatefulWidget {
  const _RecordExpenseDialog({
    required this.paymentMethods,
    required this.repository,
  });

  final List<String> paymentMethods;
  final BalancesRepository repository;

  @override
  State<_RecordExpenseDialog> createState() => _RecordExpenseDialogState();
}

class _RecordExpenseDialogState extends State<_RecordExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late String _paymentMethod;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.paymentMethods.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Catat biaya operasional'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Keperluan biaya',
                hintText: 'Contoh: Belanja gas',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Keperluan biaya wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah biaya',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = num.tryParse(value ?? '');
                return amount == null || !amount.isFinite || amount <= 0
                    ? 'Masukkan jumlah biaya lebih dari 0.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Sumber pembayaran',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: widget.paymentMethods
                  .map(
                    (method) =>
                        DropdownMenuItem(value: method, child: Text(method)),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _paymentMethod = value);
                      }
                    },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Simpan biaya'),
      ),
    ],
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.recordExpense(
        paymentMethod: _paymentMethod,
        amount: num.parse(_amountController.text.trim()),
        notes: _notesController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Biaya gagal disimpan: $error';
      });
    }
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
    required this.detail,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ReportMessage extends StatelessWidget {
  const _ReportMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _formatDateTime(DateTime? date) => date == null
    ? 'Tanggal tidak tersedia'
    : '${_formatDate(date.toLocal())}, '
          '${date.toLocal().hour.toString().padLeft(2, '0')}:'
          '${date.toLocal().minute.toString().padLeft(2, '0')}';

String _fileDate(DateTime date) =>
    '${date.year}${date.month.toString().padLeft(2, '0')}'
    '${date.day.toString().padLeft(2, '0')}';

String _statusLabel(String status) => switch (status.toLowerCase()) {
  'completed' => 'Selesai',
  'pending' => 'Open bill',
  'cancelled' => 'Dibatalkan',
  'refunded' => 'Refund',
  _ => status,
};

String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

String _formatRupiah(num amount) {
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
