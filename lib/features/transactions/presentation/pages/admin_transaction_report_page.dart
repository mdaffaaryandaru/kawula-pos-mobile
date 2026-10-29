import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../framework/widgets/responsive_data_table.dart';
import '../../../../theme/app_colors.dart';
import '../../../balances/domain/entities/balance.dart';
import '../../../balances/domain/repositories/balances_repository.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';

part '../widgets/admin_transaction_report_builder.dart';
part '../widgets/admin_report_header_widgets.dart';
part '../widgets/admin_report_filter_widgets.dart';
part '../widgets/admin_report_transaction_widgets.dart';
part '../widgets/admin_report_profit_widgets.dart';
part '../widgets/admin_report_status_badge.dart';
part '../widgets/admin_report_expense_dialog.dart';
part '../widgets/admin_report_summary_widgets.dart';

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
    final transactionsFuture = widget.checkoutRepository.getTransactions();
    if (!widget.canRecordExpenses) {
      return _ReportData(
        transactions: await transactionsFuture,
        history: const [],
      );
    }
    final results = await Future.wait<Object>([
      transactionsFuture,
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

  Future<void> _showTransactionDetails(TransactionRecord transaction) async {
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
          onCompleted: _refreshReport,
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
    final document = pw.Document();
    final isPending = transaction.isPending;
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              transaction.outletName.isEmpty
                  ? 'Kawula POS'
                  : transaction.outletName,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              isPending ? 'OPEN BILL - BELUM LUNAS' : 'STRUK PEMBAYARAN',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Divider(),
          _receiptPdfRow('No. transaksi', transaction.id),
          _receiptPdfRow('Waktu', _formatDateTime(transaction.createdAt)),
          if (transaction.cashierName.isNotEmpty)
            _receiptPdfRow('Kasir', transaction.cashierName),
          if (transaction.memberName.isNotEmpty)
            _receiptPdfRow('Member', transaction.memberName),
          if (transaction.tableNumber.isNotEmpty)
            _receiptPdfRow('No. meja', transaction.tableNumber),
          pw.Divider(),
          if (transaction.items.isEmpty)
            pw.Text('Rincian item tidak tersedia.')
          else
            for (final item in transaction.items) ...[
              _receiptPdfRow(
                '${item.quantity} x ${item.productName}',
                _formatRupiah(item.price * item.quantity),
              ),
              if (item.notes.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 6),
                  child: pw.Text('Catatan: ${item.notes}'),
                ),
            ],
          pw.Divider(),
          if (transaction.subtotal > 0)
            _receiptPdfRow('Subtotal', _formatRupiah(transaction.subtotal)),
          if (transaction.taxAmount > 0)
            _receiptPdfRow('Pajak', _formatRupiah(transaction.taxAmount)),
          if (transaction.serviceCharge > 0)
            _receiptPdfRow(
              'Biaya layanan',
              _formatRupiah(transaction.serviceCharge),
            ),
          if (transaction.discountAmount > 0)
            _receiptPdfRow(
              'Diskon',
              '- ${_formatRupiah(transaction.discountAmount)}',
            ),
          _receiptPdfRow(
            'TOTAL',
            _formatRupiah(transaction.totalAmount),
            emphasize: true,
          ),
          pw.Divider(),
          _receiptPdfRow('Metode', transaction.paymentMethod),
          if (isPending)
            _receiptPdfRow('Status', 'Belum lunas')
          else ...[
            _receiptPdfRow('Dibayar', _formatRupiah(transaction.paidAmount)),
            _receiptPdfRow(
              'Kembalian',
              _formatRupiah(transaction.changeAmount),
            ),
          ],
          if (transaction.notes.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Catatan transaksi: ${transaction.notes}'),
          ],
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text('Terima kasih')),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(
        name: 'struk-${transaction.id}.pdf',
        onLayout: (_) => document.save(),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Struk tidak dapat dicetak: $error')),
      );
    }
  }

  bool _inSelectedRange(TransactionRecord transaction) =>
      _dateInSelectedRange(transaction.createdAt);

  bool _dateInSelectedRange(DateTime? date) {
    if (date == null) return false;
    final day = _dateOnly(date.toLocal());
    return !day.isBefore(_startDate) && !day.isAfter(_endDate);
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
                  _transactionInfoCard(context, transaction),
                  const SizedBox(height: 20),
                  Text(
                    'Pesanan',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (transaction.items.isEmpty)
                    const Text('Rincian item tidak tersedia.')
                  else
                    for (final item in transaction.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                size: 19,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity} × ${_formatRupiah(item.price)}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  for (final variant in item.selectedVariants)
                                    Text(
                                      '${variant.groupName}: ${variant.optionName}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (item.notes.isNotEmpty)
                                    Text(
                                      'Catatan: ${item.notes}',
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
                              _formatRupiah(item.price * item.quantity),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  if (transaction.notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Catatan transaksi: ${transaction.notes}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _transactionTotals(context, transaction),
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

  Widget _transactionInfoCard(
    BuildContext context,
    TransactionRecord transaction,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 440 ? 2 : 1;
        return Wrap(
          runSpacing: 14,
          children: [
            _TransactionInfoCell(
              width: columns == 2 ? (constraints.maxWidth - 14) / 2 : null,
              label: 'Waktu',
              value: _formatDateTime(transaction.createdAt),
            ),
            _TransactionInfoCell(
              width: columns == 2 ? (constraints.maxWidth - 14) / 2 : null,
              label: 'Outlet & Kasir',
              value:
                  '${transaction.outletName.isEmpty ? '—' : transaction.outletName} · '
                  '${transaction.cashierName.isEmpty ? '—' : transaction.cashierName}',
            ),
            _TransactionInfoCell(
              width: columns == 2 ? (constraints.maxWidth - 14) / 2 : null,
              label: 'Metode & Status',
              value:
                  '${transaction.paymentMethod} · ${_statusLabel(transaction.status)}',
            ),
            _TransactionInfoCell(
              width: columns == 2 ? (constraints.maxWidth - 14) / 2 : null,
              label: 'Pelanggan',
              value: transaction.memberName.isEmpty
                  ? '—'
                  : transaction.memberName,
            ),
            _TransactionInfoCell(
              width: columns == 2 ? (constraints.maxWidth - 14) / 2 : null,
              label: 'No. Meja',
              value: transaction.tableNumber.isEmpty
                  ? '—'
                  : transaction.tableNumber,
            ),
          ],
        );
      },
    ),
  );

  Widget _transactionTotals(
    BuildContext context,
    TransactionRecord transaction,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        _TransactionAmountRow(label: 'Subtotal', amount: transaction.subtotal),
        if (transaction.discountAmount > 0)
          _TransactionAmountRow(
            label: 'Diskon',
            amount: -transaction.discountAmount,
          ),
        if (transaction.taxAmount > 0)
          _TransactionAmountRow(label: 'Pajak', amount: transaction.taxAmount),
        if (transaction.serviceCharge > 0)
          _TransactionAmountRow(
            label: 'Biaya Layanan',
            amount: transaction.serviceCharge,
          ),
        const Divider(height: 24),
        _TransactionAmountRow(
          label: 'Total Tagihan',
          amount: transaction.totalAmount,
          emphasized: true,
        ),
        if (transaction.isPending)
          const _TransactionAmountRow(
            label: 'Status pembayaran',
            trailingText: 'Belum lunas',
          )
        else ...[
          _TransactionAmountRow(
            label: 'Uang Diterima',
            amount: transaction.paidAmount,
          ),
          _TransactionAmountRow(
            label: 'Kembalian',
            amount: transaction.changeAmount,
          ),
        ],
        if (transaction.refundAmount > 0)
          _TransactionAmountRow(
            label: 'Refund',
            amount: transaction.refundAmount,
          ),
      ],
    ),
  );

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

class _TransactionInfoCell extends StatelessWidget {
  const _TransactionInfoCell({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final String value;
  final double? width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

class _TransactionAmountRow extends StatelessWidget {
  const _TransactionAmountRow({
    required this.label,
    this.amount,
    this.trailingText,
    this.emphasized = false,
  });

  final String label;
  final num? amount;
  final String? trailingText;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: emphasized ? FontWeight.w800 : FontWeight.normal,
      fontSize: emphasized ? 16 : 13,
      color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textStyle)),
          Text(
            trailingText ?? _formatRupiah(amount ?? 0),
            style: textStyle.copyWith(
              color: emphasized ? AppColors.textPrimary : null,
            ),
          ),
        ],
      ),
    );
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

pw.Widget _receiptPdfRow(String label, String value, {bool emphasize = false}) {
  final style = pw.TextStyle(
    fontSize: 9,
    fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.SizedBox(width: 8),
        pw.Text(value, style: style, textAlign: pw.TextAlign.right),
      ],
    ),
  );
}

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
