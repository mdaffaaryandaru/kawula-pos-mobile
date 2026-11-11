import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_offline_reconciliation_page.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';

void main() {
  late AppDatabase database;
  late AuthCubit authCubit;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    authCubit = _TestAuthCubit()..authenticate();
  });

  tearDown(() async {
    await authCubit.close();
    await database.close();
  });

  testWidgets(
    'Admin sees only local transactions from the active outlet read-only offline',
    (tester) async {
      final dao = database.offlineTransactionsDao;
      await dao.saveOfflineTransaction(
        ownerUserId: 'cashier-a',
        outletId: 'outlet-1',
        shiftId: 'shift-a',
        transactionType: 'sale',
        payload: {'total_amount': 1000},
        receiptSnapshot: {'cashier_name': 'Kasir A', 'total_amount': 1000},
        status: OfflineTransactionStatus.failed,
        lastError: 'Business rejection',
      );
      await dao.saveOfflineTransaction(
        ownerUserId: 'cashier-b',
        outletId: 'outlet-1',
        shiftId: 'shift-b',
        transactionType: 'sale',
        payload: {'total_amount': 2000},
        receiptSnapshot: {'cashier_name': 'Kasir B', 'total_amount': 2000},
        status: OfflineTransactionStatus.needsReconciliation,
      );
      await dao.saveOfflineTransaction(
        ownerUserId: 'cashier-c',
        outletId: 'outlet-2',
        shiftId: 'shift-c',
        transactionType: 'sale',
        payload: {'total_amount': 3000},
        receiptSnapshot: {'cashier_name': 'Kasir C', 'total_amount': 3000},
        status: OfflineTransactionStatus.failed,
        lastError: 'Other outlet',
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp(
            home: AdminOfflineReconciliationPage(
              admin: const AuthUser(
                id: 'admin-1',
                name: 'Admin',
                email: 'admin@example.invalid',
                role: 'Admin',
                hasPin: true,
                isOfflineSession: true,
              ),
              outletId: 'outlet-1',
              dao: dao,
              checkoutRepository: _CheckoutRepositoryFake(),
              isOutletActive: () => true,
              outletActiveStream: const Stream<bool>.empty(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Kasir A'), findsOneWidget);
      expect(find.textContaining('Kasir B'), findsOneWidget);
      expect(find.textContaining('Kasir C'), findsNothing);
      expect(find.textContaining('Mode hanya-baca'), findsOneWidget);
      expect(find.text('Cari kandidat server'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}

class _AuthRepositoryFake extends Fake implements AuthRepository {}

class _TestAuthCubit extends AuthCubit {
  _TestAuthCubit() : super(_AuthRepositoryFake());

  void authenticate() {
    emit(
      const AuthAuthenticated(
        AuthUser(
          id: 'admin-1',
          name: 'Admin',
          email: 'admin@example.invalid',
          role: 'Admin',
          hasPin: true,
          isOfflineSession: true,
        ),
      ),
    );
  }
}

class _CheckoutRepositoryFake extends Fake implements CheckoutRepository {
  @override
  Future<List<TransactionRecord>> getTransactions() async => const [];
}
