// Dart imports:
import 'dart:convert';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

// Project imports:
import 'package:kawula_pos/features/balances/domain/entities/balance.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_report_expense_dialog.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_report_summary_widgets.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_transaction_report_builder.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/transaction_receipt_component.dart';
import 'package:kawula_pos/theme/app_colors.dart';

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
    final rows = <List<String>>[
      [
        'ID',
        'Tanggal',
        'Status',
        'Metode pembayaran',
        'No. meja',
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
          transaction.tableNumber,
          transaction.totalAmount.toString(),
          transaction.cogs.toString(),
          transaction.refundAmount.toString(),
          transaction.items.map((item) => item.productName).join('; '),
        ],
      ),
    ];
    final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    final fileName =
        'laporan-transaksi-${_fileDate(startDate)}-'
        '${_fileDate(endDate)}.csv';
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: 'Laporan transaksi Kawula',
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

  Future<void> showTransactionDetails(TransactionRecord transaction) async {
    try {
      final detail = await widget.checkoutRepository.getTransaction(
        transaction.id,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _TransactionDetailsDialog(
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

class _TransactionDetailsDialog extends StatefulWidget {
  const _TransactionDetailsDialog({
    required this.transaction,
    required this.repository,
    required this.onCompleted,
    required this.onPrint,
  });

  final TransactionRecord transaction;
  final CheckoutRepository repository;
  final VoidCallback onCompleted;
  final ValueChanged<TransactionRecord> onPrint;

  @override
  State<_TransactionDetailsDialog> createState() =>
      _TransactionDetailsDialogState();
}

class _TransactionDetailsDialogState extends State<_TransactionDetailsDialog> {
  var _isSubmittingAction = false;
  String? _actionError;

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final status = transaction.status.toLowerCase();
    final canCancel = status == 'pending' || status == 'completed';
    final canRefund = status == 'completed';
    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: screenSize.height * .9,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Transaksi',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        SelectableText(
                          transaction.id,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cetak struk',
                    onPressed: _isSubmittingAction
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onPrint(transaction);
                          },
                    icon: const Icon(Icons.print_outlined),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: _isSubmittingAction
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TransactionReceiptCard(
                    receipt: TransactionReceiptData.fromTransaction(
                      transaction,
                    ),
                  ),
                  if (transaction.refundAmount > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Refund: ${_formatRupiah(transaction.refundAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  if (transaction.refundReason.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Alasan: ${transaction.refundReason}'),
                  ],
                  if (_actionError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _actionError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canCancel || canRefund) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (canCancel)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmittingAction
                              ? null
                              : () => _runTransactionAction(refund: false),
                          icon: const Icon(Icons.block_outlined, size: 18),
                          label: const Text('Batalkan Transaksi'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: Color(0xFFFECACA)),
                          ),
                        ),
                      ),
                    if (canCancel && canRefund) const SizedBox(width: 10),
                    if (canRefund)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSubmittingAction
                              ? null
                              : () => _runTransactionAction(refund: true),
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: const Text('Refund Transaksi'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_isSubmittingAction)
              const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }

  Future<void> _runTransactionAction({required bool refund}) async {
    final input = await showDialog<_TransactionActionInput>(
      context: context,
      builder: (_) => _TransactionActionPrompt(
        refund: refund,
        transactionId: widget.transaction.id,
      ),
    );
    if (input == null || !mounted) return;
    setState(() {
      _isSubmittingAction = true;
      _actionError = null;
    });
    try {
      if (refund) {
        await widget.repository.refundTransaction(
          transactionId: widget.transaction.id,
          pin: input.pin!,
          reason: input.reason,
        );
      } else {
        await widget.repository.cancelTransaction(
          transactionId: widget.transaction.id,
          reason: input.reason,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCompleted();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refund
                ? 'Transaksi berhasil direfund.'
                : 'Transaksi berhasil dibatalkan.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmittingAction = false;
        _actionError = 'Operasi gagal: $error';
      });
    }
  }
}

class _TransactionActionInput {
  const _TransactionActionInput({required this.reason, this.pin});

  final String reason;
  final String? pin;
}

class _TransactionActionPrompt extends StatefulWidget {
  const _TransactionActionPrompt({
    required this.refund,
    required this.transactionId,
  });

  final bool refund;
  final String transactionId;

  @override
  State<_TransactionActionPrompt> createState() =>
      _TransactionActionPromptState();
}

class _TransactionActionPromptState extends State<_TransactionActionPrompt> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.refund ? 'Refund transaksi?' : 'Batalkan transaksi?'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ID transaksi: ${widget.transactionId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: widget.refund
                    ? 'Alasan refund'
                    : 'Alasan pembatalan',
              ),
              maxLines: 2,
              validator: (value) =>
                  widget.refund && (value?.trim().length ?? 0) < 3
                  ? 'Alasan refund minimal 3 karakter.'
                  : null,
            ),
            if (widget.refund) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(labelText: 'PIN kasir'),
                validator: (value) => (value?.trim().length ?? 0) != 4
                    ? 'PIN harus terdiri dari 4 digit.'
                    : null,
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Kembali'),
      ),
      FilledButton(
        style: widget.refund
            ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
            : null,
        onPressed: _submit,
        child: Text(widget.refund ? 'Proses Refund' : 'Batalkan Transaksi'),
      ),
    ],
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _TransactionActionInput(
        reason: _reasonController.text.trim().isEmpty
            ? 'Pembatalan transaksi'
            : _reasonController.text.trim(),
        pin: widget.refund ? _pinController.text.trim() : null,
      ),
    );
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

String formatDate(DateTime date) => _formatDate(date);

String formatDateTime(DateTime? date) => _formatDateTime(date);

String statusLabel(String status) => _statusLabel(status);

String formatRupiah(num amount) => _formatRupiah(amount);
