import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/entities/admin_shift_detail.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/admin_shifts_repository.dart';
import 'package:kawula_pos/features/shifts/presentation/pages/admin_shifts_page.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';

void main() {
  testWidgets('shows shift list with status and backend-provided summaries', (
    tester,
  ) async {
    final repository = _FakeAdminShiftsRepository();

    await tester.pumpWidget(
      MaterialApp(home: AdminShiftsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 shift ditemukan'), findsOneWidget);
    expect(find.text('1 sedang berjalan · mengikuti filter'), findsOneWidget);
    expect(find.text('Kasir Satu'), findsOneWidget);
    expect(find.text('Sedang berjalan'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsNWidgets(2));
    expect(find.text('Rp 25.000'), findsOneWidget);
    expect(find.text('Ditutup otomatis'), findsOneWidget);
  });

  testWidgets('shows shift details and submits confirmed force close', (
    tester,
  ) async {
    final repository = _FakeAdminShiftsRepository();

    await tester.pumpWidget(
      MaterialApp(home: AdminShiftsPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kasir Satu'));
    await tester.pumpAndSettle();

    expect(find.text('Rekap kas'), findsOneWidget);
    expect(find.text('Kas yang diharapkan'), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);

    await tester.tap(find.text('Paksa tutup shift'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '70000');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Kasir selesai bertugas',
    );
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Perkiraan selisih -Rp 5.000'), findsOneWidget);
    await tester.tap(find.text('Tutup shift'));
    await tester.pumpAndSettle();

    expect(repository.closedShiftId, 'open-shift');
    expect(repository.closedWithActualCash, 70000);
    expect(repository.closedWithNotes, 'Kasir selesai bertugas');
    expect(find.text('Shift kasir'), findsOneWidget);
  });
}

class _FakeAdminShiftsRepository implements AdminShiftsRepository {
  String? closedShiftId;
  num? closedWithActualCash;
  String? closedWithNotes;

  final openShift = ActiveShift(
    id: 'open-shift',
    status: 'open',
    startTime: DateTime(2026, 10, 28, 8),
    startingCash: 50000,
    expectedCash: 75000,
    totalSales: 25000,
    totalTransactions: 1,
    outletName: 'Kawula Outlet',
    cashierName: 'Kasir Satu',
    cashierEmail: 'kasir@kawula.id',
  );

  final closedShift = ActiveShift(
    id: 'closed-shift',
    status: 'auto_closed',
    startTime: DateTime(2026, 10, 27, 8),
    startingCash: 50000,
    expectedCash: 65000,
    totalSales: 15000,
    totalTransactions: 1,
    outletName: 'Kawula Outlet',
    cashierName: 'Kasir Dua',
  );

  @override
  Future<List<ActiveShift>> getShifts({String? status}) async {
    final shifts = [openShift, closedShift];
    return status == null
        ? shifts
        : shifts.where((shift) => shift.status == status).toList();
  }

  @override
  Future<AdminShiftDetail> getShiftDetail(String shiftId) async {
    return AdminShiftDetail(
      shift: openShift,
      transactions: [
        TransactionRecord(
          id: 'transaction-id',
          status: 'completed',
          totalAmount: 25000,
          paymentMethod: 'CASH',
          paidAmount: 25000,
          changeAmount: 0,
          createdAt: DateTime(2026, 10, 28, 9),
          items: const [
            TransactionRecordItem(
              productName: 'Kopi Susu',
              quantity: 1,
              price: 25000,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<ActiveShift> forceCloseShift({
    required String shiftId,
    required num actualCash,
    required String notes,
  }) async {
    closedShiftId = shiftId;
    closedWithActualCash = actualCash;
    closedWithNotes = notes;
    return openShift;
  }
}
