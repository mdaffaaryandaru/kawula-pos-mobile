// Dart imports:
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Project imports:
import 'package:kawula_pos/config/api_config.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';

class TransactionReceiptData {
  const TransactionReceiptData({
    required this.transactionId,
    required this.status,
    required this.storeName,
    required this.address,
    required this.logoUrl,
    required this.createdAt,
    required this.cashierName,
    required this.memberName,
    required this.tableNumber,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceCharge,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paidAmount,
    required this.changeAmount,
    required this.notes,
  });

  factory TransactionReceiptData.fromCheckout({
    required CheckoutResult result,
    required CheckoutSettings settings,
    String memberName = '',
    String memberPhone = '',
    String tableNumber = '',
  }) => TransactionReceiptData(
    transactionId: result.id,
    status: result.status,
    storeName: settings.storeName.isEmpty ? 'Kawula' : settings.storeName,
    address: settings.address,
    logoUrl: settings.logoUrl,
    createdAt: result.createdAt,
    cashierName: '',
    memberName: memberName.isEmpty
        ? result.memberName
        : memberPhone.isEmpty
        ? memberName
        : '$memberName · $memberPhone',
    tableNumber: result.tableNumber.isEmpty ? tableNumber : result.tableNumber,
    items: [
      for (final item in result.items)
        TransactionReceiptItem(
          productName: item.productName,
          quantity: item.quantity,
          price: item.price,
          notes: item.notes,
          variants: [
            for (final variant in item.selectedVariants)
              TransactionReceiptVariant(
                groupName: variant.groupName,
                optionName: variant.optionName,
              ),
          ],
        ),
    ],
    subtotal: result.subtotal,
    taxAmount: result.taxAmount,
    serviceCharge: result.serviceCharge,
    discountAmount: result.discountAmount,
    totalAmount: result.totalAmount,
    paymentMethod: result.paymentMethod,
    paidAmount: result.paidAmount,
    changeAmount: result.changeAmount,
    notes: result.notes,
  );

  factory TransactionReceiptData.fromTransaction(
    TransactionRecord record, {
    String logoUrl = '',
  }) => TransactionReceiptData(
    transactionId: record.id,
    status: record.status,
    storeName: record.outletName.isEmpty ? 'Kawula' : record.outletName,
    address: '',
    logoUrl: logoUrl,
    createdAt: record.createdAt,
    cashierName: record.cashierName,
    memberName: record.memberName,
    tableNumber: record.tableNumber,
    items: [
      for (final item in record.items)
        TransactionReceiptItem(
          productName: item.productName,
          quantity: item.quantity,
          price: item.price,
          notes: item.notes,
          variants: [
            for (final variant in item.selectedVariants)
              TransactionReceiptVariant(
                groupName: variant.groupName,
                optionName: variant.optionName,
              ),
          ],
        ),
    ],
    subtotal: record.subtotal,
    taxAmount: record.taxAmount,
    serviceCharge: record.serviceCharge,
    discountAmount: record.discountAmount,
    totalAmount: record.totalAmount,
    paymentMethod: record.paymentMethod,
    paidAmount: record.paidAmount,
    changeAmount: record.changeAmount,
    notes: record.notes,
  );

  final String transactionId;
  final String status;
  final String storeName;
  final String address;
  final String logoUrl;
  final DateTime? createdAt;
  final String cashierName;
  final String memberName;
  final String tableNumber;
  final List<TransactionReceiptItem> items;
  final num? subtotal;
  final num? taxAmount;
  final num? serviceCharge;
  final num? discountAmount;
  final num totalAmount;
  final String paymentMethod;
  final num paidAmount;
  final num changeAmount;
  final String notes;

  bool get isPending => status.toLowerCase() == 'pending';
}

class TransactionReceiptItem {
  const TransactionReceiptItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.notes,
    required this.variants,
  });

  final String productName;
  final int quantity;
  final num price;
  final String notes;
  final List<TransactionReceiptVariant> variants;
}

class TransactionReceiptVariant {
  const TransactionReceiptVariant({
    required this.groupName,
    required this.optionName,
  });

  final String groupName;
  final String optionName;
}

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

String formatTransactionReceiptDate(DateTime? date) {
  if (date == null) return 'Tidak tersedia';
  final localDate = date.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  return '$day/$month/${localDate.year} $hour:$minute';
}

String resolveTransactionReceiptLogoUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed != null && parsed.hasScheme) return url;
  return Uri.parse(ApiConfig.baseUrl).resolve(url).toString();
}

Future<Uint8List?> loadTransactionReceiptLogo(
  TransactionReceiptData receipt,
) async {
  if (receipt.logoUrl.isEmpty) return null;
  final response = await http.get(
    Uri.parse(resolveTransactionReceiptLogoUrl(receipt.logoUrl)),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Logo toko gagal dimuat (HTTP ${response.statusCode}).');
  }
  return response.bodyBytes;
}

pw.Document buildTransactionReceiptPdf(
  TransactionReceiptData receipt, {
  Uint8List? logoBytes,
}) {
  final document = pw.Document();
  final logo = logoBytes == null ? null : pw.MemoryImage(logoBytes);
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, 297 * PdfPageFormat.mm),
      margin: const pw.EdgeInsets.all(8),
      build: (context) => [
        if (logo != null) ...[
          pw.Center(child: pw.Image(logo, width: 72, height: 72)),
          pw.SizedBox(height: 6),
        ],
        pw.Center(
          child: pw.Text(
            receipt.storeName,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        if (receipt.address.isNotEmpty)
          pw.Center(
            child: pw.Text(receipt.address, textAlign: pw.TextAlign.center),
          ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            receipt.isPending ? 'OPEN BILL - BELUM LUNAS' : 'STRUK PEMBAYARAN',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Divider(),
        _receiptPdfRow('No. transaksi', receipt.transactionId),
        _receiptPdfRow(
          'Waktu',
          formatTransactionReceiptDate(receipt.createdAt),
        ),
        if (receipt.cashierName.isNotEmpty)
          _receiptPdfRow('Kasir', receipt.cashierName),
        if (receipt.memberName.isNotEmpty)
          _receiptPdfRow('Member', receipt.memberName),
        if (receipt.tableNumber.isNotEmpty)
          _receiptPdfRow('No. meja', receipt.tableNumber),
        pw.Divider(),
        if (receipt.items.isEmpty)
          pw.Text('Rincian item tidak tersedia.')
        else
          for (final item in receipt.items) ...[
            _receiptPdfRow(
              '${item.quantity} x ${item.productName}',
              formatRupiah(item.price * item.quantity),
            ),
            for (final variant in item.variants)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6),
                child: pw.Text('${variant.groupName}: ${variant.optionName}'),
              ),
            if (item.notes.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6),
                child: pw.Text('Catatan: ${item.notes}'),
              ),
          ],
        pw.Divider(),
        if (receipt.subtotal != null)
          _receiptPdfRow('Subtotal', formatRupiah(receipt.subtotal!)),
        if (receipt.taxAmount != null)
          _receiptPdfRow('Pajak', formatRupiah(receipt.taxAmount!)),
        if (receipt.serviceCharge != null)
          _receiptPdfRow('Biaya layanan', formatRupiah(receipt.serviceCharge!)),
        if (receipt.discountAmount != null && receipt.discountAmount! > 0)
          _receiptPdfRow(
            'Diskon',
            '- ${formatRupiah(receipt.discountAmount!)}',
          ),
        _receiptPdfRow(
          'TOTAL',
          formatRupiah(receipt.totalAmount),
          emphasized: true,
        ),
        pw.Divider(),
        _receiptPdfRow('Metode', receipt.paymentMethod),
        if (receipt.isPending)
          _receiptPdfRow('Status', 'Belum lunas')
        else ...[
          _receiptPdfRow('Dibayar', formatRupiah(receipt.paidAmount)),
          _receiptPdfRow('Kembalian', formatRupiah(receipt.changeAmount)),
        ],
        if (receipt.notes.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text('Catatan transaksi: ${receipt.notes}'),
        ],
        pw.SizedBox(height: 12),
        pw.Center(child: pw.Text('Terima kasih')),
      ],
    ),
  );
  return document;
}

pw.Widget _receiptPdfRow(
  String label,
  String value, {
  bool emphasized = false,
}) {
  final style = pw.TextStyle(
    fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      children: [
        pw.SizedBox(width: 72, child: pw.Text(label, style: style)),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(value, style: style, textAlign: pw.TextAlign.right),
        ),
      ],
    ),
  );
}
