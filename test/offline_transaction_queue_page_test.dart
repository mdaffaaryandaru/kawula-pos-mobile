import 'package:drift/native.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/members/domain/entities/member_reward_claim.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/entities/admin_shift_detail.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/transactions/data/services/offline_transaction_sync_service.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/data/repositories/offline_transaction_queue_repository_impl.dart';
import 'package:kawula_pos/features/transactions/domain/entities/offline_transaction_queue_item.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/offline_transaction_queue_page.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/offline_transaction_queue_widgets.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';

void main() {
  late AppDatabase database;
  late OfflineTransactionsDao dao;
  late OfflineMasterDataCache networkCache;
  late bool databaseClosed;

  setUp(() {
    databaseClosed = false;
    database = AppDatabase(
      executor: DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    dao = database.offlineTransactionsDao;
    networkCache = OfflineMasterDataCache(database.cachedRecordsDao);
    networkCache.markOnline();
    addTearDown(() async {
      if (!databaseClosed) await database.close();
    });
  });

  Future<void> pumpAnimations(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpQueuePage(
    WidgetTester tester, {
    OfflineTransactionSyncService? syncService,
    OfflineMasterDataCache? offlineMasterDataCache,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OfflineTransactionQueuePage(
          user: const AuthUser(
            id: 'cashier-1',
            name: 'Kasir A',
            email: 'kasir@example.com',
            role: 'Kasir',
            hasPin: true,
          ),
          outletId: 'outlet-1',
          shiftId: 'shift-1',
          queueRepository: OfflineTransactionQueueRepositoryImpl(dao),
          syncService:
              syncService ??
              OfflineTransactionSyncService(
                _FakeCheckoutRepository(),
                dao,
                activeShiftsRepository: _FakeShiftsRepository(),
              ),
          offlineMasterDataCache: offlineMasterDataCache ?? networkCache,
        ),
      ),
    );
    await pumpAnimations(tester);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
      databaseClosed = true;
    });
  }

  Future<void> saveTransaction({
    String localId = 'OFF-pending',
    DateTime? createdAtLocal,
    OfflineTransactionStatus status = OfflineTransactionStatus.pendingSync,
    String? lastError,
    bool openBill = false,
    Map<String, Object?>? receiptSnapshot,
  }) async {
    await dao.saveOfflineTransaction(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      shiftId: 'shift-1',
      transactionType: openBill ? 'open_bill' : 'sale',
      payload: {
        'items': [
          {
            'product_id': 'product-1',
            'product_name': 'Kopi Susu',
            'quantity': 2,
            'unit_price': 1000,
            'selected_variants': const [],
          },
        ],
        'total_amount': 2000,
        'payment_method': openBill ? 'OPEN_BILL' : 'CASH',
        'paid_amount': openBill ? 0 : 2000,
      },
      receiptSnapshot:
          receiptSnapshot ??
          {
            'transaction_id': localId,
            'status': status.databaseValue,
            'store_name': 'Kawula Store',
            'address': 'Jl. Contoh 1',
            'logo_url': '',
            'outlet_id': 'outlet-1',
            'outlet_name': 'Outlet Utama',
            'cashier_id': 'cashier-1',
            'cashier_name': 'Kasir A',
            'created_at_local': DateTime(2026, 11, 12).toIso8601String(),
            'items': [
              {
                'product_id': 'product-1',
                'product_name': 'Kopi Susu',
                'quantity': 2,
                'unit_price': 1000,
                'discount_amount': 0,
                'notes': '',
                'selected_variants': [
                  {'group_name': 'Ukuran', 'option_name': 'Besar'},
                ],
              },
            ],
            'subtotal': 2000,
            'tax_amount': 0,
            'service_charge': 0,
            'discount_amount': 0,
            'total_amount': 2000,
            'payment_method': openBill ? 'OPEN_BILL' : 'CASH',
            'paid_amount': openBill ? 0 : 2000,
            'change_amount': 0,
            'member_id': null,
            'member_name': '',
            'table_number': '',
            'sync_marker': 'OFFLINE_SYNC:$localId',
            'sync_status': status.databaseValue,
          },
      localId: localId,
      syncMarker: 'OFFLINE_SYNC:$localId',
      createdAtLocal: createdAtLocal,
      status: status,
      lastError: lastError,
    );
  }

  testWidgets('shows queued offline transactions and counts', (tester) async {
    await dao.saveOfflineTransaction(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      shiftId: 'shift-1',
      transactionType: 'sale',
      payload: {'items': [], 'total_amount': 25000},
      receiptSnapshot: {'total_amount': 25000},
    );
    await dao.saveOfflineTransaction(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      shiftId: 'shift-1',
      transactionType: 'sale',
      payload: {'items': [], 'total_amount': 50000},
      receiptSnapshot: {'total_amount': 50000},
      status: OfflineTransactionStatus.failed,
      lastError: 'Stok tidak cukup',
    );
    await dao.saveOfflineTransaction(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      shiftId: 'shift-1',
      transactionType: 'sale',
      payload: {'items': [], 'total_amount': 30000},
      receiptSnapshot: {'total_amount': 30000},
      status: OfflineTransactionStatus.syncing,
    );
    await dao.saveOfflineTransaction(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      shiftId: 'shift-older',
      transactionType: 'sale',
      payload: {'items': [], 'total_amount': 10000},
      receiptSnapshot: {'total_amount': 10000},
    );

    await pumpQueuePage(
      tester,
      syncService: OfflineTransactionSyncService(
        _FakeCheckoutRepository(),
        dao,
        activeShiftsRepository: _FakeShiftsRepository(),
      ),
    );

    expect(find.text('Antrean Offline'), findsOneWidget);
    expect(find.text('Menunggu: 1'), findsOneWidget);
    expect(find.text('Sedang disinkronkan: 1'), findsOneWidget);
    expect(find.text('Gagal: 1'), findsOneWidget);
    expect(find.textContaining('OFF-'), findsWidgets);
    expect(find.text('Sinkronkan Antrean'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('shows structured receipt details from the local snapshot', (
    tester,
  ) async {
    await saveTransaction(localId: 'OFF-receipt');
    await pumpQueuePage(tester);

    await tester.tap(find.textContaining('OFF-receipt'));
    await pumpAnimations(tester);

    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('OFF-receipt'), findsWidgets);
    expect(find.textContaining('Kopi Susu'), findsOneWidget);
    expect(find.text('2 × Kopi Susu'), findsOneWidget);
    expect(find.text('Harga satuan: Rp 1.000'), findsOneWidget);
    expect(find.text('Subtotal item'), findsOneWidget);
    expect(find.text('Rp 2.000'), findsWidgets);
    expect(find.text('Ukuran: Besar'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Menunggu'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('"total_amount":'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tutup'));
    await pumpAnimations(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('receipt detail dialog fits a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final record = OfflineTransactionQueueItem(
      localId: 'OFF-small-screen',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      shiftId: 'shift-1',
      transactionType: 'sale',
      payloadJson: '{}',
      receiptSnapshotJson:
          '{"store_name":"Kawula","payment_method":"CASH",'
          '"total_amount":1000,"paid_amount":1000,"change_amount":0,'
          '"items":[{"product_name":"Kopi","quantity":1,"unit_price":1000}]}',
      status: 'pending_sync',
      createdAtLocal: DateTime(2026, 11, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineQueueTransactionDetailDialog(
            record: record,
            audit: const [],
          ),
        ),
      ),
    );
    await pumpAnimations(tester);

    expect(find.textContaining('Kopi'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Tutup'));
    await pumpAnimations(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Open Bill as unpaid without paid or change rows', (
    tester,
  ) async {
    await saveTransaction(localId: 'OFF-open-bill', openBill: true);
    await pumpQueuePage(tester);

    await tester.tap(find.textContaining('OFF-open-bill'));
    await pumpAnimations(tester);

    expect(find.text('Open Bill · Belum lunas'), findsOneWidget);
    expect(find.text('Belum lunas'), findsOneWidget);
    expect(find.text('Dibayar'), findsNothing);
    expect(find.text('Kembalian'), findsNothing);
    expect(find.textContaining('"total_amount":'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unsupported receipt snapshot displays a safe fallback', (
    tester,
  ) async {
    await saveTransaction(
      localId: 'OFF-unsupported',
      receiptSnapshot: const {'total_amount': 1000},
    );
    await pumpQueuePage(tester);

    await tester.tap(find.textContaining('OFF-unsupported'));
    await pumpAnimations(tester);

    expect(find.text('Detail struk tidak tersedia'), findsOneWidget);
    expect(find.textContaining('"total_amount":'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tutup'));
    await pumpAnimations(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid receipt JSON does not prevent dialog closing', (
    tester,
  ) async {
    final record = OfflineTransactionQueueItem(
      localId: 'OFF-invalid-json',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      shiftId: 'shift-1',
      transactionType: 'sale',
      payloadJson: '{}',
      receiptSnapshotJson: '{invalid',
      status: 'pending_sync',
      createdAtLocal: DateTime(2026, 11, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineQueueTransactionDetailDialog(
            record: record,
            audit: const [],
          ),
        ),
      ),
    );
    await pumpAnimations(tester);

    expect(find.text('Detail struk tidak tersedia'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Tutup'));
    await pumpAnimations(tester);
    expect(find.byType(OfflineQueueTransactionDetailDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'counts unresolved transactions within owner, outlet, and shift scope',
    () async {
      await saveTransaction(localId: 'OFF-pending');
      await saveTransaction(
        localId: 'OFF-syncing',
        status: OfflineTransactionStatus.syncing,
      );
      await saveTransaction(
        localId: 'OFF-failed',
        status: OfflineTransactionStatus.failed,
      );
      await saveTransaction(
        localId: 'OFF-reconciliation',
        status: OfflineTransactionStatus.needsReconciliation,
      );
      await saveTransaction(
        localId: 'OFF-synced',
        status: OfflineTransactionStatus.synced,
      );
      await dao.saveOfflineTransaction(
        ownerUserId: 'cashier-2',
        outletId: 'outlet-1',
        shiftId: 'shift-1',
        transactionType: 'sale',
        payload: const {},
        receiptSnapshot: const {},
        localId: 'OFF-other-owner',
        syncMarker: 'OFFLINE_SYNC:OFF-other-owner',
      );
      await dao.saveOfflineTransaction(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-2',
        shiftId: 'shift-1',
        transactionType: 'sale',
        payload: const {},
        receiptSnapshot: const {},
        localId: 'OFF-other-outlet',
        syncMarker: 'OFFLINE_SYNC:OFF-other-outlet',
      );
      await dao.saveOfflineTransaction(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        shiftId: 'shift-2',
        transactionType: 'sale',
        payload: const {},
        receiptSnapshot: const {},
        localId: 'OFF-other-shift',
        syncMarker: 'OFFLINE_SYNC:OFF-other-shift',
      );

      final repository = OfflineTransactionQueueRepositoryImpl(dao);
      final count = await repository.getUnresolvedTransactionCount(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        shiftId: 'shift-1',
      );

      expect(count, 4);
    },
  );

  testWidgets('PIN dialog cannot be opened twice and can be cancelled', (
    tester,
  ) async {
    await saveTransaction();
    await pumpQueuePage(tester);

    await tester.tap(find.text('Sinkronkan Antrean'));
    await pumpAnimations(tester);
    expect(find.text('Sinkronisasi antrean'), findsOneWidget);
    final syncFab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(syncFab.onPressed, isNull);

    expect(find.text('Sinkronisasi antrean'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await pumpAnimations(tester);

    expect(find.text('Sinkronisasi antrean'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(find.text('Sinkronkan Antrean'), findsOneWidget);
  });

  testWidgets('submits PIN once and safely closes the dialog', (tester) async {
    final repository = _FakeCheckoutRepository();
    final shiftsRepository = _FakeShiftsRepository()
      ..activeShift = ActiveShift(
        id: 'shift-1',
        status: 'open',
        startTime: DateTime(2026),
        startingCash: 0,
        expectedCash: 0,
        totalSales: 0,
        totalTransactions: 0,
        outletId: 'outlet-1',
      );
    final syncService = OfflineTransactionSyncService(
      repository,
      dao,
      activeShiftsRepository: shiftsRepository,
    );
    await saveTransaction();

    await pumpQueuePage(tester, syncService: syncService);
    await tester.tap(find.text('Sinkronkan Antrean'));
    await pumpAnimations(tester);
    await tester.enterText(find.byType(TextField), '2468');
    await tester.tap(find.widgetWithText(FilledButton, 'Sinkronkan'));
    await pumpAnimations(tester);

    expect(repository.createTransactionCalls, 1);
    expect(repository.receivedPin, '2468');
    expect(find.textContaining('1 berhasil'), findsOneWidget);
    expect(find.text('Sinkronisasi antrean'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsNothing);

    final transaction = (await dao.getTransactionsByOwner('cashier-1')).single;
    expect(transaction.status, 'synced');
    expect(transaction.payloadJson, isNot(contains('2468')));
    expect(transaction.receiptSnapshotJson, isNot(contains('2468')));
  });

  testWidgets(
    'lists newest first and preserves that order with status filter',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await saveTransaction(
        localId: 'OFF-old',
        createdAtLocal: DateTime(2026, 1, 1),
      );
      await saveTransaction(
        localId: 'OFF-same-a',
        createdAtLocal: DateTime(2026, 1, 2),
        status: OfflineTransactionStatus.failed,
        lastError: 'Rejected',
      );
      await saveTransaction(
        localId: 'OFF-same-z',
        createdAtLocal: DateTime(2026, 1, 2),
        status: OfflineTransactionStatus.pendingSync,
      );
      await saveTransaction(
        localId: 'OFF-new',
        createdAtLocal: DateTime(2026, 1, 3),
        status: OfflineTransactionStatus.synced,
      );
      await pumpQueuePage(tester);

      final oldPosition = tester.getTopLeft(find.textContaining('OFF-old')).dy;
      final sameAPosition = tester
          .getTopLeft(find.textContaining('OFF-same-a'))
          .dy;
      final sameZPosition = tester
          .getTopLeft(find.textContaining('OFF-same-z'))
          .dy;
      final newPosition = tester.getTopLeft(find.textContaining('OFF-new')).dy;
      expect(newPosition, lessThan(sameZPosition));
      expect(sameZPosition, lessThan(sameAPosition));
      expect(sameAPosition, lessThan(oldPosition));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await pumpAnimations(tester);
      await tester.tap(find.text('Gagal').last);
      await pumpAnimations(tester);
      expect(find.textContaining('OFF-same-a'), findsOneWidget);
      expect(find.textContaining('OFF-same-z'), findsNothing);
      expect(find.textContaining('OFF-old'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('offline disables syncing but keeps pending badge visible', (
    tester,
  ) async {
    await saveTransaction(
      localId: 'OFF-pending',
      status: OfflineTransactionStatus.pendingSync,
    );
    await saveTransaction(
      localId: 'OFF-failed',
      status: OfflineTransactionStatus.failed,
      lastError: 'Rejected',
    );
    await saveTransaction(
      localId: 'OFF-needs-reconciliation',
      status: OfflineTransactionStatus.needsReconciliation,
      lastError: 'Manual review',
    );
    networkCache.markOffline();
    await pumpQueuePage(tester);

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.onPressed, isNull);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Gagal: 1'), findsOneWidget);
    expect(find.text('Rekonsiliasi: 1'), findsOneWidget);
  });

  testWidgets('FAB is centered and hidden when no pending transactions exist', (
    tester,
  ) async {
    await pumpQueuePage(tester);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending sync FAB uses centerFloat location', (tester) async {
    await saveTransaction();
    await pumpQueuePage(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final fabRect = tester.getRect(find.byType(FloatingActionButton));
    expect(
      scaffold.floatingActionButtonLocation,
      FloatingActionButtonLocation.centerFloat,
    );
    expect(
      fabRect.center.dx,
      closeTo(tester.getSize(find.byType(Scaffold)).width / 2, 1),
    );
  });
}

class _FakeCheckoutRepository implements CheckoutRepository {
  int createTransactionCalls = 0;
  String? receivedPin;

  @override
  Future<List<CheckoutPaymentMethod>> getPaymentMethods() async => const [];

  @override
  Future<CheckoutSettings> getSettings() async =>
      const CheckoutSettings(taxPercentage: 0, serviceCharge: 0);

  @override
  Future<List<TransactionRecord>> getTransactions() async => const [];

  @override
  Future<TransactionRecord> getTransaction(String transactionId) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionRecord> cancelTransaction({
    required String transactionId,
    required String reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionRecord> refundTransaction({
    required String transactionId,
    required String pin,
    required String reason,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Member>> searchMembers(String search) async => const [];

  @override
  Future<MemberRewardClaim> claimMemberReward(String memberId) async {
    throw UnimplementedError();
  }

  @override
  Future<CheckoutResult> payPendingTransaction({
    required String transactionId,
    required String paymentMethod,
    required num paidAmount,
    required String pin,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CheckoutResult> createTransaction({
    required String outletId,
    required List<CartItem> items,
    required num estimatedTotal,
    required num serviceCharge,
    required String paymentMethod,
    required num paidAmount,
    required String? pin,
    required bool openBill,
    String? memberId,
    String? tableNumber,
  }) async {
    createTransactionCalls++;
    receivedPin = pin;
    return CheckoutResult(
      id: 'server-1',
      status: 'completed',
      totalAmount: estimatedTotal,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: 0,
      createdAt: DateTime(2026),
    );
  }
}

class _FakeShiftsRepository implements ShiftsRepository {
  ActiveShift? activeShift;

  @override
  Future<ActiveShift?> getActive() async => activeShift;

  @override
  Future<CashAvailability> getCashAvailability() async =>
      const CashAvailability(
        globalBalance: 0,
        reservedCash: 0,
        availableCash: 0,
      );

  @override
  Future<void> openShift({
    required num startingCash,
    required String pin,
  }) async {}

  @override
  Future<ActiveShift> closeShift({
    required String shiftId,
    required num actualCash,
    String? pin,
    String? notes,
  }) async => throw UnimplementedError();

  @override
  Future<List<ActiveShift>> getShifts({String? status}) async => const [];

  @override
  Future<AdminShiftDetail> getShiftDetail(String shiftId) async =>
      throw UnimplementedError();

  @override
  Future<ActiveShift> forceCloseShift({
    required String shiftId,
    required num actualCash,
    required String notes,
  }) async => throw UnimplementedError();
}
