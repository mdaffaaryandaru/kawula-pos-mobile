import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawula_pos/features/transactions/data/repositories/offline_transaction_queue_repository_impl.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/transactions/domain/services/offline_transaction_reconciliation.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_offline_reconciliation_page.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/offline_transaction_reconciliation_widgets.dart';
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
              queueRepository: OfflineTransactionQueueRepositoryImpl(dao),
              reconciliation: _OfflineTransactionReconciliationFake(),
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

  testWidgets(
    'candidate dialog shows endpoint warning and outside-window candidates',
    (tester) async {
      final localCreatedAt = DateTime.utc(2026, 11, 10, 10);
      final remote = TransactionRecord(
        id: 'remote-1',
        status: 'completed',
        totalAmount: 12000,
        paymentMethod: 'CASH',
        paidAmount: 12000,
        changeAmount: 0,
        createdAt: DateTime.utc(2026, 11, 10, 10),
        items: const [],
      );
      final olderRemote = TransactionRecord(
        id: 'remote-older',
        status: 'completed',
        totalAmount: 12000,
        paymentMethod: 'CASH',
        paidAmount: 12000,
        changeAmount: 0,
        createdAt: DateTime.utc(2026, 11, 11, 11),
        items: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showReconciliationCandidateDialog(context, [
                  remote,
                  olderRemote,
                ], localCreatedAt: localCreatedAt),
                child: const Text('Open candidates'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open candidates'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('mungkin tidak mencakup semua transaksi'),
        findsOneWidget,
      );
      expect(find.text('remote-1'), findsOneWidget);
      expect(find.text('remote-older'), findsOneWidget);
      expect(
        find.text('Di luar rentang relevansi utama ±24 jam.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('match dialog shows local/server time and total difference', (
    tester,
  ) async {
    final local = OfflineTransactionQueueItem(
      localId: 'OFF-local',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      shiftId: 'shift-1',
      transactionType: 'sale',
      payloadJson: '{"total_amount":12000}',
      receiptSnapshotJson: '{"total_amount":12000}',
      status: 'needs_reconciliation',
      createdAtLocal: DateTime.utc(2026, 11, 10, 10),
    );
    final remote = TransactionRecord(
      id: 'remote-1',
      status: 'completed',
      totalAmount: 11999,
      paymentMethod: 'CASH',
      paidAmount: 11999,
      changeAmount: 0,
      createdAt: DateTime.utc(2026, 11, 10, 10, 1),
      items: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showReconciliationMatchDialog(
                context,
                local: local,
                remote: remote,
              ),
              child: const Text('Open match'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open match'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Waktu lokal:'), findsOneWidget);
    expect(find.textContaining('Waktu server:'), findsOneWidget);
    expect(find.textContaining('Selisih total:'), findsOneWidget);
  });
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

class _OfflineTransactionReconciliationFake extends Fake
    implements OfflineTransactionReconciliation {}
