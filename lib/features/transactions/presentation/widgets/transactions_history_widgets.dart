part of '../pages/transactions_history_page.dart';

// Extensions keep history rendering close to its page-owned state.
// ignore_for_file: invalid_use_of_protected_member

extension _TransactionsHistoryWidgets on _TransactionsHistoryPageState {
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
}
