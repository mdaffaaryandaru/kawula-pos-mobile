import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/presentation/services/transaction_report_csv.dart';

void main() {
  test('builds the report CSV with escaped fields and the expected columns', () {
    final transaction = TransactionRecord(
      id: 'tx-1',
      status: 'completed',
      totalAmount: 12500,
      paymentMethod: 'CASH',
      paidAmount: 12500,
      changeAmount: 0,
      createdAt: DateTime.utc(2025, 1, 2, 3, 4),
      tableNumber: 'A, "1"',
      items: const [
        TransactionRecordItem(
          productName: 'Kopi "Susu"',
          quantity: 1,
          price: 12500,
        ),
      ],
      cogs: 5000,
      refundAmount: 0,
    );

    expect(
      TransactionReportCsv.buildCsv([transaction]),
      '"ID","Tanggal","Status","Metode pembayaran","No. meja","Total",'
      '"HPP","Refund","Produk"\r\n'
      '"tx-1","2025-01-02T03:04:00.000Z","completed","CASH","A, ""1""",'
      '"12500","5000","0","Kopi ""Susu"""',
    );
  });

  test('adds a UTF-8 BOM and formats the report file name', () {
    final bytes = TransactionReportCsv.buildCsvBytes(const []);

    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(bytes.sublist(3)), TransactionReportCsv.buildCsv(const []));
    expect(
      TransactionReportCsv.buildFileName(
        DateTime(2025, 1, 2),
        DateTime(2025, 1, 31),
      ),
      'laporan-transaksi-20250102-20250131.csv',
    );
  });
}
