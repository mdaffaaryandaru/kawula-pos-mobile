// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_transaction_report_page.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_report_filter_widgets.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_report_profit_widgets.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_report_summary_widgets.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/admin_report_transaction_widgets.dart';
import 'package:kawula_pos/framework/widgets/master_data_header.dart';
import 'package:kawula_pos/theme/app_colors.dart';

extension AdminTransactionReportBuilder on AdminTransactionReportPageState {
  Widget buildReport(BuildContext context, ReportData data) {
    final transactions = data.transactions.where(inSelectedRange).toList()
      ..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    final expenses = data.history.where((entry) {
      return entry.type.toLowerCase() == 'expense' &&
          dateInSelectedRange(entry.createdAt);
    }).toList();
    final normalizedQuery = query.trim().toLowerCase();
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
          statusFilter == 'all' ||
          transaction.status.toLowerCase() == statusFilter;
      final matchesPayment =
          paymentFilter == 'all' ||
          transaction.paymentMethod.toLowerCase() == paymentFilter;
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
        MasterDataHeader(
          eyebrow: 'LAPORAN',
          title: 'Transaksi Masuk',
          description: 'Default menampilkan transaksi hari ini, termasuk penjualan, open bill, dan pembatalan.',
          onRefresh: refreshReport,
          addLabel: 'Catat Biaya',
          onAdd: widget.canRecordExpenses
              ? () => recordExpense(data.history)
              : null,
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
                ReportMetric(
                  label: 'Omzet penjualan',
                  value: formatRupiah(sales),
                  detail:
                      'Cash: ${formatRupiah(_salesByMethod(completed, 'cash'))} · '
                      'Non-cash: ${formatRupiah(_salesByMethod(completed, 'cash', exclude: true))}',
                  color: const Color(0xFF2563EB),
                  background: const Color(0xFFF0F7FF),
                ),
                if (widget.canRecordExpenses)
                  ReportMetric(
                    label: 'Laba bersih',
                    value: formatRupiah(netProfit),
                    detail: 'Omzet - HPP - Pajak - Layanan - Biaya',
                    color: const Color(0xFF059669),
                    background: const Color(0xFFECFDF5),
                  ),
                if (widget.canRecordExpenses)
                  ReportMetric(
                    label: 'Beban & operasional',
                    value: formatRupiah(cogs + expenseTotal),
                    detail:
                        'HPP: ${formatRupiah(cogs)} · Biaya: ${formatRupiah(expenseTotal)}',
                    color: const Color(0xFFDC2626),
                    background: const Color(0xFFFFF1F2),
                  ),
                ReportMetric(
                  label: 'Open bill / transaksi',
                  value: formatRupiah(openBills),
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
        ReportFilters(
          startDate: startDate,
          endDate: endDate,
          query: query,
          status: statusFilter,
          payment: paymentFilter,
          paymentMethods: paymentMethods,
          resultCount: filteredTransactions.length,
          onChooseRange: chooseDateRange,
          onQueryChanged: (value) => updateState(() => query = value),
          onStatusChanged: (value) =>
              updateState(() => statusFilter = value ?? 'all'),
          onPaymentChanged: (value) =>
              updateState(() => paymentFilter = value ?? 'all'),
          onExport: filteredTransactions.isEmpty
              ? null
              : () => exportCsv(filteredTransactions),
        ),
        const SizedBox(height: 12),
        if (filteredTransactions.isEmpty)
          const ReportMessage(
            message: 'Tidak ada transaksi sesuai filter yang dipilih.',
          )
        else
          TransactionsTable(
            transactions: filteredTransactions,
            onTap: showTransactionDetails,
          ),
        if (widget.canRecordExpenses) ...[
          const SizedBox(height: 16),
          ProfitSummary(
            sales: sales,
            cogs: cogs,
            serviceCharge: serviceCharge,
            tax: tax,
            expenses: expenseTotal,
            netProfit: netProfit,
            expenseEntries: expenses,
          ),
        ],
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
}
