import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/framework/widgets/master_data_row_actions.dart';
void main() {
  testWidgets('runs edit and delete callbacks from shared row actions', (
    tester,
  ) async {
    var edited = false;
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MasterDataRowActions(
            onEdit: () => edited = true,
            onDelete: () => deleted = true,
            leadingActions: const [Icon(Icons.info_outline)],
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Edit'));
    await tester.tap(find.byTooltip('Hapus'));

    expect(edited, isTrue);
    expect(deleted, isTrue);
    expect(find.byType(IconButton), findsNWidgets(2));
  });

  testWidgets('asks for confirmation before destructive actions', (tester) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final confirmed = await MasterDataDeleteConfirmation.show(
                  context,
                  title: 'Hapus item?',
                  message: 'Item akan dihapus.',
                );
                if (confirmed) deleted = true;
              },
              child: const Text('Mulai hapus'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mulai hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Item akan dihapus.'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);

    await tester.tap(find.text('Mulai hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
