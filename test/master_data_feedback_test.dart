import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/framework/widgets/master_data_feedback.dart';

void main() {
  testWidgets('shows a standard loading indicator and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MasterDataLoadingState(message: 'Memuat kategori...'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Memuat kategori...'), findsOneWidget);
  });

  testWidgets('shows empty message and invokes optional action', (
    tester,
  ) async {
    var actionCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MasterDataEmptyState(
            title: 'Belum ada data',
            message: 'Tambahkan data pertama.',
            actionLabel: 'Tambah',
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Belum ada data'), findsOneWidget);
    expect(find.text('Tambahkan data pertama.'), findsOneWidget);
    await tester.tap(find.text('Tambah'));
    expect(actionCalled, isTrue);
  });

  testWidgets('shows error detail and retries on request', (tester) async {
    var retryCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MasterDataErrorState(
            title: 'Gagal memuat data',
            message: 'Koneksi terputus.',
            onRetry: () => retryCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Gagal memuat data'), findsOneWidget);
    expect(find.text('Koneksi terputus.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    expect(retryCalled, isTrue);
  });
}
