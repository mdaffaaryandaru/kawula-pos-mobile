// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:printing/printing.dart';

// Project imports:
import 'package:kawula_pos/features/balances/domain/entities/balance.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/dialogs/transaction_details_dialog.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_report_expense_dialog.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_report_summary_widgets.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_transaction_report_builder.dart';
import 'package:kawula_pos/features/transactions/presentation/models/transaction_receipt_data.dart';
import 'package:kawula_pos/features/transactions/presentation/services/transaction_receipt_pdf.dart';
import 'package:kawula_pos/features/transactions/presentation/services/transaction_report_csv.dart';

class ReportData {
  const ReportData({required this.transactions, required this.history});

  final List<TransactionRecord> transactions;
  final List<BalanceHistoryEntry> history;
}

class AdminTransactionReportPage extends StatefulWidget {
  const AdminTransactionReportPage({
    super.key,
    required this.checkoutRepository,
    required this.balancesRepository,
    this.canRecordExpenses = true,
  });

  final CheckoutRepository checkoutRepository;
  final BalancesRepository balancesRepository;
  final bool canRecordExpenses;

  @override
  State<AdminTransactionReportPage> createState() =>
      AdminTransactionReportPageState();
}

class AdminTransactionReportPageState
    extends State<AdminTransactionReportPage> {
  late DateTime startDate;
  late DateTime endDate;
  late Future<ReportData> _report;
  String query = '';
  String statusFilter = 'all';
  String paymentFilter = 'all';

  void updateState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    startDate = today;
    endDate = today;
    _report = _loadReport();
  }

  Future<ReportData> _loadReport() async {
    final transactionsFuture = widget.checkoutRepository.getTransactions();
    if (!widget.canRecordExpenses) {
      return ReportData(
        transactions: await transactionsFuture,
        history: const [],
      );
    }
    final results = await Future.wait<Object>([
      transactionsFuture,
      widget.balancesRepository.getHistory(),
    ]);
    return ReportData(
      transactions: results[0] as List<TransactionRecord>,
      history: results[1] as List<BalanceHistoryEntry>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Transaksi')),
      body: FutureBuilder<ReportData>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ReportMessage(
              message: 'Laporan gagal dimuat: ${snapshot.error}',
              action: TextButton(
                onPressed: refreshReport,
                child: const Text('Coba lagi'),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const ReportMessage(message: 'Data laporan tidak tersedia.');
          }
          return buildReport(context, data);
        },
      ),
    );
  }

  void refreshReport() {
    setState(() {
      _report = _loadReport();
    });
  }

  Future<void> recordExpense(List<BalanceHistoryEntry> history) async {
    final methods = history
        .map((entry) => entry.paymentMethod)
        .where((method) => method.isNotEmpty)
        .toSet();
    methods.add('CASH');
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => RecordExpenseDialog(
        paymentMethods: methods.toList()..sort(),
        repository: widget.balancesRepository,
      ),
    );
    if (!mounted || success != true) return;
    refreshReport();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Biaya berhasil dicatat.')));
  }

  Future<void> chooseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );
    if (!mounted || range == null) return;
    setState(() {
      startDate = _dateOnly(range.start);
      endDate = _dateOnly(range.end);
    });
  }

  Future<void> exportCsv(List<TransactionRecord> transactions) async {
    try {
      await TransactionReportCsv.share(
        transactions: transactions,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV tidak dapat dibagikan: $error')),
      );
    }
  }

  Future<void> showTransactionDetails(TransactionRecord transaction) async {
    try {
      final detail = await widget.checkoutRepository.getTransaction(
        transaction.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => TransactionDetailsDialog(
          transaction: detail.withFallbackDetails(transaction),
          repository: widget.checkoutRepository,
          onCompleted: refreshReport,
          onPrint: _printTransactionReceipt,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detail transaksi gagal dimuat: $error')),
      );
    }
  }

  Future<void> _printTransactionReceipt(TransactionRecord transaction) async {
    try {
      final settings = await widget.checkoutRepository.getSettings();
      final receipt = TransactionReceiptData.fromTransaction(
        transaction,
        logoUrl: settings.logoUrl,
      );
      final logoBytes = await loadTransactionReceiptLogo(receipt);
      await Printing.layoutPdf(
        name: 'struk-${transaction.id}.pdf',
        onLayout: (_) =>
            buildTransactionReceiptPdf(receipt, logoBytes: logoBytes).save(),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Struk tidak dapat dicetak: $error')),
      );
    }
  }

  bool inSelectedRange(TransactionRecord transaction) =>
      dateInSelectedRange(transaction.createdAt);

  bool dateInSelectedRange(DateTime? date) {
    if (date == null) return false;
    final day = _dateOnly(date.toLocal());
    return !day.isBefore(startDate) && !day.isAfter(endDate);
  }
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

String _statusLabel(String status) => switch (status.toLowerCase()) {
  'completed' => 'Selesai',
  'pending' => 'Open bill',
  'cancelled' => 'Dibatalkan',
  'refunded' => 'Refund',
  _ => status,
};

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

String formatDate(DateTime date) => _formatDate(date);

String formatDateTime(DateTime? date) => _formatDateTime(date);

String statusLabel(String status) => _statusLabel(status);

String formatRupiah(num amount) => _formatRupiah(amount);
