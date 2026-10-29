import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/framework/widgets/master_data_status_badge.dart';

void main() {
  testWidgets('shows consistent active and inactive status labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              MasterDataStatusBadge(isActive: true),
              MasterDataStatusBadge(isActive: false),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Nonaktif'), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(2));
    for (final chip in tester.widgetList<Chip>(find.byType(Chip))) {
      expect(chip.visualDensity, VisualDensity.compact);
      expect(chip.side, BorderSide.none);
    }
  });
}
