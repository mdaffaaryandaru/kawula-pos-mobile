// Dart imports:
import 'dart:typed_data';

// Package imports:
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Project imports:
import 'package:kawula_pos/config/api_config.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/transactions/presentation/models/transaction_receipt_data.dart';

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

  try {
    final response = await http
        .get(Uri.parse(resolveTransactionReceiptLogoUrl(receipt.logoUrl)))
        .timeout(const Duration(seconds: 4));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    if (response.bodyBytes.isEmpty) return null;

    return response.bodyBytes;
  } catch (_) {
    // Logo bersifat opsional.
    // Kegagalan mengambil logo tidak boleh
    // menggagalkan pembuatan PDF struk.
    return null;
  }
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
        if (receipt.outletName.isNotEmpty)
          pw.Center(child: pw.Text('Outlet: ${receipt.outletName}')),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            receipt.isPending
                ? 'OPEN BILL - BELUM LUNAS'
                : receipt.isOffline
                ? receipt.isReconciliation
                      ? 'STATUS SERVER BELUM DIPASTIKAN'
                      : 'BELUM TERSINKRON'
                : 'STRUK PEMBAYARAN',
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
        if (receipt.isOffline)
          _receiptPdfRow(
            'Status',
            receipt.isReconciliation
                ? 'Status server belum dapat dipastikan'
                : 'BELUM TERSINKRON',
          )
        else if (receipt.isPending)
          _receiptPdfRow('Status', 'Belum lunas')
        else ...[
          _receiptPdfRow('Dibayar', formatRupiah(receipt.paidAmount)),
          _receiptPdfRow('Kembalian', formatRupiah(receipt.changeAmount)),
        ],
        if (receipt.isOffline && receipt.isPending)
          _receiptPdfRow('Pembayaran', 'Belum lunas'),
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
