part of '../pages/admin_transaction_report_page.dart';

// Extensions keep report rendering close to its page-owned state.
// ignore_for_file: invalid_use_of_protected_member

extension _AdminTransactionReportWidgets on _AdminTransactionReportPageState {
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
          onExpense: widget.canRecordExpenses
              ? () => _recordExpense(data.history)
              : null,
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
                if (widget.canRecordExpenses)
                  _ReportMetric(
                    label: 'Laba bersih',
                    value: _formatRupiah(netProfit),
                    detail: 'Omzet - HPP - Pajak - Layanan - Biaya',
                    color: const Color(0xFF059669),
                    background: const Color(0xFFECFDF5),
                  ),
                if (widget.canRecordExpenses)
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
        if (widget.canRecordExpenses) ...[
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
