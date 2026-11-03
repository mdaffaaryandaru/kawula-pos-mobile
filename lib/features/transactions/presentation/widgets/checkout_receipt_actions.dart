// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

// Project imports:
import 'package:kawula_pos/features/transactions/presentation/pages/checkout_page.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/transaction_receipt_component.dart';

extension CheckoutReceiptActions on CheckoutPageState {
  Future<void> shareReceipt(TransactionReceiptData receipt) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: receipt.isPending
              ? 'Open bill ${receipt.transactionId}'
              : 'Struk transaksi ${receipt.transactionId}',
          files: [
            XFile.fromData(
              await buildTransactionReceiptPdf(
                receipt,
                logoBytes: await loadTransactionReceiptLogo(receipt),
              ).save(),
              mimeType: 'application/pdf',
              name: 'struk-${receipt.transactionId}.pdf',
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Struk tidak dapat dibagikan: $error')),
      );
    }
  }

  Future<void> printReceipt(TransactionReceiptData receipt) async {
    try {
      final logoBytes = await loadTransactionReceiptLogo(receipt);
      await Printing.layoutPdf(
        name: 'struk-${receipt.transactionId}.pdf',
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
}
