// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/checkout_page.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/checkout_receipt_actions.dart';
import 'package:kawula_pos/features/transactions/presentation/models/transaction_receipt_data.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/transaction_receipt_card.dart';

extension CheckoutReceiptWidgets on CheckoutPageState {
  Widget completed(CheckoutResult result, CheckoutSettings settings) {
    final isPending = result.status.toLowerCase() == 'pending';
    final theme = Theme.of(context);
    final receipt = TransactionReceiptData.fromCheckout(
      result: result,
      settings: settings,
      memberName: selectedMember?.name ?? '',
      tableNumber: tableNumberController.text.trim(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isPending
                  ? theme.colorScheme.tertiaryContainer
                  : const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(
                  isPending
                      ? Icons.pending_actions_outlined
                      : Icons.check_circle_outline,
                  size: 40,
                  color: isPending
                      ? theme.colorScheme.onTertiaryContainer
                      : const Color(0xFF16834A),
                ),
                const SizedBox(height: 8),
                Text(
                  isPending
                      ? 'Open bill berhasil dibuat'
                      : 'Pembayaran berhasil',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending
                      ? 'Transaksi ini belum lunas'
                      : 'Transaksi berhasil dicatat',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TransactionReceiptCard(receipt: receipt),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => shareReceipt(receipt),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Bagikan struk'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => printReceipt(receipt),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Cetak struk'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali ke katalog'),
          ),
        ],
      ),
    );
  }
}
