// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/transactions/presentation/models/transaction_receipt_data.dart';
import 'package:kawula_pos/features/transactions/presentation/services/transaction_receipt_pdf.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';

class TransactionReceiptCard extends StatelessWidget {
  const TransactionReceiptCard({super.key, required this.receipt});

  final TransactionReceiptData receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: 76,
                height: 76,
                child: receipt.logoUrl.isEmpty
                    ? _fallbackReceiptLogo()
                    : Image.network(
                        resolveTransactionReceiptLogoUrl(receipt.logoUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _fallbackReceiptLogo(),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              receipt.storeName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (receipt.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(receipt.address, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),
            const Divider(),
            Text(
              receipt.isPending
                  ? 'OPEN BILL · BELUM LUNAS'
                  : 'STRUK PEMBAYARAN',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: receipt.isPending
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _ReceiptInfoRow(
              label: 'No. transaksi',
              value: receipt.transactionId,
            ),
            _ReceiptInfoRow(
              label: 'Waktu',
              value: formatTransactionReceiptDate(receipt.createdAt),
            ),
            if (receipt.cashierName.isNotEmpty)
              _ReceiptInfoRow(label: 'Kasir', value: receipt.cashierName),
            if (receipt.memberName.isNotEmpty)
              _ReceiptInfoRow(label: 'Member', value: receipt.memberName),
            if (receipt.tableNumber.isNotEmpty)
              _ReceiptInfoRow(label: 'No. meja', value: receipt.tableNumber),
            const Divider(height: 24),
            if (receipt.items.isEmpty)
              const Text(
                'Rincian item tidak tersedia.',
                textAlign: TextAlign.center,
              )
            else
              for (final item in receipt.items) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('${item.quantity} × ${item.productName}'),
                    ),
                    const SizedBox(width: 8),
                    Text(formatRupiah(item.price * item.quantity)),
                  ],
                ),
                for (final variant in item.variants)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 2),
                    child: Text(
                      '${variant.groupName}: ${variant.optionName}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (item.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 2),
                    child: Text(
                      'Catatan: ${item.notes}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            const Divider(height: 20),
            if (receipt.subtotal != null)
              _ReceiptInfoRow(
                label: 'Subtotal',
                value: formatRupiah(receipt.subtotal!),
              ),
            if (receipt.taxAmount != null)
              _ReceiptInfoRow(
                label: 'Pajak',
                value: formatRupiah(receipt.taxAmount!),
              ),
            if (receipt.serviceCharge != null)
              _ReceiptInfoRow(
                label: 'Biaya layanan',
                value: formatRupiah(receipt.serviceCharge!),
              ),
            if (receipt.discountAmount != null && receipt.discountAmount! > 0)
              _ReceiptInfoRow(
                label: 'Diskon',
                value: '- ${formatRupiah(receipt.discountAmount!)}',
              ),
            _ReceiptInfoRow(
              label: 'TOTAL',
              value: formatRupiah(receipt.totalAmount),
              emphasized: true,
            ),
            const Divider(height: 20),
            _ReceiptInfoRow(label: 'Metode', value: receipt.paymentMethod),
            if (receipt.isPending)
              const _ReceiptInfoRow(label: 'Status', value: 'Belum lunas')
            else ...[
              _ReceiptInfoRow(
                label: 'Dibayar',
                value: formatRupiah(receipt.paidAmount),
              ),
              _ReceiptInfoRow(
                label: 'Kembalian',
                value: formatRupiah(receipt.changeAmount),
              ),
            ],
            if (receipt.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Catatan transaksi: ${receipt.notes}'),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const Text('Terima kasih', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ReceiptInfoRow extends StatelessWidget {
  const _ReceiptInfoRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 82, child: Text(label, style: style, softWrap: true)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: style,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _fallbackReceiptLogo() => ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
);
