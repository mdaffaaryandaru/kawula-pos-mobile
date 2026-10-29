import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/balance.dart';
import 'balance_history_widgets.dart';
import 'balance_summary_widgets.dart';

class BalancesOverview extends StatelessWidget {
  const BalancesOverview({
    super.key,
    required this.balances,
    required this.history,
    required this.onRefresh,
    required this.onAdjustBalance,
    required this.onAdjustPaymentMethod,
    required this.onRecordExpense,
    this.errorMessage,
  });

  final List<BalanceAccount> balances;
  final List<BalanceHistoryEntry> history;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdjustBalance;
  final ValueChanged<String> onAdjustPaymentMethod;
  final VoidCallback onRecordExpense;

  @override
  Widget build(BuildContext context) {
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
            if (errorMessage != null)
              MaterialBanner(
                content: Text(errorMessage!),
                actions: [
                  TextButton(
                    onPressed: onRefresh,
                    child: const Text('Muat ulang'),
                  ),
                ],
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    _pageHeader(context),
                    const SizedBox(height: 24),
                    _balanceCards(context),
                    const SizedBox(height: 24),
                    BalanceHistorySection(history: history),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageHeader(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onAdjustBalance,
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
              onPressed: onRefresh,
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
                if (action == 'expense') onRecordExpense();
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

  Widget _balanceCards(BuildContext context) {
    final totalBalance = balances.fold<num>(
      0,
      (total, account) => total + account.balance,
    );
    final cards = <Widget>[
      TotalBalanceCard(totalBalance: totalBalance),
      ...balances.map(
        (account) => PaymentBalanceCard(
          account: account,
          onAdjust: () => onAdjustPaymentMethod(account.paymentMethod),
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
                child: const FinanceEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  message: 'Belum ada saldo tercatat.',
                ),
              ),
          ],
        );
      },
    );
  }
}
