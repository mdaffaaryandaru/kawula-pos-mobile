// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/balances/domain/entities/balance.dart';
import 'package:kawula_pos/features/balances/presentation/widgets/balance_history_widgets.dart';
import 'package:kawula_pos/features/balances/presentation/widgets/balance_summary_widgets.dart';
import 'package:kawula_pos/framework/widgets/master_data_header.dart';
import 'package:kawula_pos/theme/app_colors.dart';

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
    return MasterDataHeader(
      eyebrow: 'ADMINISTRASI',
      title: 'Keuangan & Saldo',
      description: 'Pantau pergerakan uang tunai maupun non-tunai dan tetapkan saldo awal perusahaan.',
      onRefresh: onRefresh,
      addLabel: 'Sesuaikan Saldo',
      onAdd: onAdjustBalance,
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
