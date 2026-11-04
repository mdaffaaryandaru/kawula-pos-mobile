// Dart imports:
import 'dart:convert';
import 'dart:typed_data';

// Package imports:
import 'package:share_plus/share_plus.dart';

// Project imports:
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';

class TransactionReportCsv {
  const TransactionReportCsv._();

  static String buildCsv(List<TransactionRecord> transactions) {
    final rows = <List<String>>[
      [
        'ID',
        'Tanggal',
        'Status',
        'Metode pembayaran',
        'No. meja',
        'Total',
        'HPP',
        'Refund',
        'Produk',
      ],
      ...transactions.map(
        (transaction) => [
          transaction.id,
          transaction.createdAt?.toIso8601String() ?? '',
          transaction.status,
          transaction.paymentMethod,
          transaction.tableNumber,
          transaction.totalAmount.toString(),
          transaction.cogs.toString(),
          transaction.refundAmount.toString(),
          transaction.items.map((item) => item.productName).join('; '),
        ],
      ),
    ];
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  static Uint8List buildCsvBytes(List<TransactionRecord> transactions) =>
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(buildCsv(transactions))]);

  static String buildFileName(DateTime startDate, DateTime endDate) =>
      'laporan-transaksi-${_fileDate(startDate)}-${_fileDate(endDate)}.csv';

  static Future<void> share({
    required List<TransactionRecord> transactions,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Laporan transaksi Kawula',
        files: [
          XFile.fromData(
            buildCsvBytes(transactions),
            mimeType: 'text/csv',
            name: buildFileName(startDate, endDate),
          ),
        ],
      ),
    );
  }
}

String _fileDate(DateTime date) =>
    '${date.year}${date.month.toString().padLeft(2, '0')}'
    '${date.day.toString().padLeft(2, '0')}';

String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';
