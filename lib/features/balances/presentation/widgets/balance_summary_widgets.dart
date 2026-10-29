import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/balance.dart';
import 'balance_formatters.dart';

class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key, required this.totalBalance});

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
          formatBalanceRupiah(totalBalance),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF1E3A8A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class PaymentBalanceCard extends StatelessWidget {
  const PaymentBalanceCard({
    super.key,
    required this.account,
    required this.onAdjust,
  });

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
                  '${paymentMethodLabel(code)} ($code)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(paymentMethodIcon(code), color: color),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatBalanceRupiah(account.balance),
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
