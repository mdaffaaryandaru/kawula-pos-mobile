import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/users/presentation/widgets/admin_users_list.dart';

void main() {
  testWidgets('filters users and clears the search query', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminUsersList(
            users: const [
              AuthUser(
                id: 'admin',
                name: 'Admin Utama',
                email: 'admin@example.com',
                role: 'Admin',
                hasPin: true,
              ),
              AuthUser(
                id: 'cashier',
                name: 'Kasir Utama',
                email: 'kasir@example.com',
                role: 'Kasir',
                hasPin: false,
              ),
            ],
            errorMessage: null,
            onRefresh: () async {},
            onAdd: () {},
            onEdit: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'kasir@');
    await tester.pumpAndSettle();

    expect(find.text('Kasir Utama'), findsOneWidget);
    expect(find.text('Admin Utama'), findsNothing);
    expect(find.text('Semua Role'), findsOneWidget);

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();

    expect(find.text('Kasir Utama'), findsOneWidget);
    expect(find.text('Admin Utama'), findsOneWidget);
  });
}
