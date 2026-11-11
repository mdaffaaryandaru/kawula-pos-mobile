import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/members/domain/entities/member_reward_claim.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/entities/admin_shift_detail.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/transactions/data/services/offline_transaction_sync_service.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';

void main() {
  late AppDatabase database;
  late _FakeCheckoutRepository delegate;
  late _FakeShiftsRepository shiftsRepository;
  late OfflineTransactionSyncService service;

  Future<void> insertTransaction({
    required String localId,
    required String ownerUserId,
    required String outletId,
    required OfflineTransactionStatus status,
    String shiftId = 'shift-1',
    String transactionType = 'sale',
    Object payload = const {},
    Object receiptSnapshot = const {},
    String? lastError,
  }) async {
    await database.offlineTransactionsDao.saveOfflineTransaction(
      ownerUserId: ownerUserId,
      outletId: outletId,
      shiftId: shiftId,
      transactionType: transactionType,
      payload: payload,
      receiptSnapshot: receiptSnapshot,
      lastError: lastError,
      createdAtLocal: DateTime.now().add(
        Duration(minutes: insertTransactionCallCount++),
      ),
      localId: localId,
      syncMarker: 'OFFLINE_SYNC:$localId',
      status: status,
    );
  }

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    delegate = _FakeCheckoutRepository();
    shiftsRepository = _FakeShiftsRepository()
      ..activeShift = _activeShift(outletId: 'outlet-1');
    service = OfflineTransactionSyncService(
      delegate,
      database.offlineTransactionsDao,
      activeShiftsRepository: shiftsRepository,
    );
    insertTransactionCallCount = 0;
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'syncs pending transactions in FIFO order and saves remote IDs',
    () async {
      await insertTransaction(
        localId: 'OFF-aaa',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'outlet_id': 'outlet-1',
          'items': [
            {
              'product_id': 'product-1',
              'product_name': 'Kopi',
              'quantity': 1,
              'unit_price': 1000,
              'selected_variants': const [],
            },
          ],
          'total_amount': 1100,
          'service_charge': 50,
          'payment_method': 'CASH',
          'paid_amount': 1100,
        },
        receiptSnapshot: {'store_name': 'Kawula'},
      );

      await insertTransaction(
        localId: 'OFF-bbb',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'outlet_id': 'outlet-1',
          'items': [
            {
              'product_id': 'product-2',
              'product_name': 'Teh',
              'quantity': 1,
              'unit_price': 600,
              'selected_variants': const [],
            },
          ],
          'total_amount': 650,
          'service_charge': 0,
          'payment_method': 'CASH',
          'paid_amount': 650,
        },
        receiptSnapshot: {'store_name': 'Kawula'},
      );

      final summary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );
      final rows = await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      );

      expect(summary.successCount, 2);
      expect(summary.stopped, isFalse);
      expect(delegate.calls, ['product-1', 'product-2']);
      expect(rows.every((row) => row.status == 'synced'), isTrue);
      expect(rows.map((row) => row.remoteTransactionId), [
        'server-1',
        'server-2',
      ]);
    },
  );

  test('Admin syncs only its own transactions for the active outlet', () async {
    await insertTransaction(
      localId: 'OFF-admin',
      ownerUserId: 'admin-1',
      outletId: 'outlet-1',
      status: OfflineTransactionStatus.pendingSync,
      payload: {
        'outlet_id': 'outlet-1',
        'items': [
          {
            'product_id': 'admin-product',
            'product_name': 'Kopi',
            'quantity': 1,
            'unit_price': 1000,
            'selected_variants': const [],
          },
        ],
        'total_amount': 1100,
        'service_charge': 50,
        'payment_method': 'CASH',
        'paid_amount': 1100,
      },
    );
    await insertTransaction(
      localId: 'OFF-cashier',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      status: OfflineTransactionStatus.pendingSync,
      payload: const {},
    );

    final summary = await service.syncOfflineTransactions(
      ownerUserId: 'admin-1',
      outletId: 'outlet-1',
      role: 'Admin',
      pin: '1234',
    );
    final adminTransactions = await database.offlineTransactionsDao
        .getTransactionsByOwner('admin-1');
    final cashierTransactions = await database.offlineTransactionsDao
        .getTransactionsByOwner('cashier-1');

    expect(summary.successCount, 1);
    expect(delegate.calls, ['admin-product']);
    expect(adminTransactions.single.status, 'synced');
    expect(cashierTransactions.single.status, 'pending_sync');
  });

  test(
    'does not send queued transactions without a matching active server shift',
    () async {
      await insertTransaction(
        localId: 'OFF-no-shift',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'items': [
            {
              'product_id': 'product-1',
              'product_name': 'Kopi',
              'quantity': 1,
              'unit_price': 1000,
              'selected_variants': const [],
            },
          ],
          'total_amount': 1000,
          'payment_method': 'CASH',
          'paid_amount': 1000,
        },
      );
      shiftsRepository.activeShift = null;

      final summary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );
      final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      )).single;

      expect(summary.stopped, isTrue);
      expect(summary.stopReason, contains('shift aktif online'));
      expect(delegate.calls, isEmpty);
      expect(row.status, 'pending_sync');
    },
  );

  test(
    'does not send queued transactions through another outlet shift',
    () async {
      await insertTransaction(
        localId: 'OFF-wrong-outlet',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'items': [
            {
              'product_id': 'product-1',
              'product_name': 'Kopi',
              'quantity': 1,
              'unit_price': 1000,
              'selected_variants': const [],
            },
          ],
          'total_amount': 1000,
          'payment_method': 'CASH',
          'paid_amount': 1000,
        },
      );
      shiftsRepository.activeShift = _activeShift(outletId: 'outlet-2');

      final summary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );

      expect(summary.stopped, isTrue);
      expect(delegate.calls, isEmpty);
    },
  );

  test('sync queue is isolated by owner and active outlet', () async {
    const payload = {
      'items': [
        {
          'product_id': 'product-1',
          'product_name': 'Kopi',
          'quantity': 1,
          'unit_price': 1000,
          'selected_variants': [],
        },
      ],
      'total_amount': 1000,
      'payment_method': 'CASH',
      'paid_amount': 1000,
    };
    await insertTransaction(
      localId: 'OFF-active-outlet',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      status: OfflineTransactionStatus.pendingSync,
      payload: payload,
    );
    await insertTransaction(
      localId: 'OFF-other-outlet',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-2',
      status: OfflineTransactionStatus.pendingSync,
      payload: payload,
    );
    await insertTransaction(
      localId: 'OFF-other-owner',
      ownerUserId: 'cashier-2',
      outletId: 'outlet-1',
      status: OfflineTransactionStatus.pendingSync,
      payload: payload,
    );

    final summary = await service.syncOfflineTransactions(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      role: 'Kasir',
      pin: '1234',
    );
    final activeOutlet = await database.offlineTransactionsDao
        .getTransactionByLocalId('OFF-active-outlet');
    final otherOutlet = await database.offlineTransactionsDao
        .getTransactionByLocalId('OFF-other-outlet');
    final otherOwner = await database.offlineTransactionsDao
        .getTransactionByLocalId('OFF-other-owner');

    expect(summary.successCount, 1);
    expect(activeOutlet?.status, 'synced');
    expect(otherOutlet?.status, 'pending_sync');
    expect(otherOwner?.status, 'pending_sync');
    expect(delegate.calls, ['product-1']);
  });

  test(
    'recovers stale syncing before checking existing reconciliation',
    () async {
      await insertTransaction(
        localId: 'OFF-stale',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.syncing,
      );
      await insertTransaction(
        localId: 'OFF-needs-review',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.needsReconciliation,
      );

      final summary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );
      final stale = await database.offlineTransactionsDao
          .getTransactionByLocalId('OFF-stale');

      expect(summary.stopped, isTrue);
      expect(summary.needsReconciliationCount, 2);
      expect(stale?.status, 'needs_reconciliation');
      expect(stale?.lastError, contains('sebelumnya terputus'));
      expect(delegate.calls, isEmpty);
    },
  );

  test(
    'does not recover syncing while another batch holds the sync lock',
    () async {
      await insertTransaction(
        localId: 'OFF-in-progress',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'items': [
            {
              'product_id': 'product-1',
              'product_name': 'Kopi',
              'quantity': 1,
              'unit_price': 1000,
              'selected_variants': const [],
            },
          ],
          'total_amount': 1000,
          'payment_method': 'CASH',
          'paid_amount': 1000,
        },
      );
      delegate.createGate = Completer<void>();
      delegate.createStarted = Completer<void>();

      final firstSync = service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );
      await delegate.createStarted!.future;
      final secondSummary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );
      final row = await database.offlineTransactionsDao.getTransactionByLocalId(
        'OFF-in-progress',
      );

      expect(secondSummary.stopped, isTrue);
      expect(row?.status, 'syncing');
      delegate.createGate!.complete();
      await firstSync;
      expect(
        (await database.offlineTransactionsDao.getTransactionByLocalId(
          'OFF-in-progress',
        ))?.status,
        'synced',
      );
    },
  );

  test(
    'summary keeps previously failed rows visible without pending rows',
    () async {
      await insertTransaction(
        localId: 'OFF-already-failed',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.failed,
        lastError: 'Business validation rejected',
      );

      final summary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );

      expect(summary.successCount, 0);
      expect(summary.failedCount, 0);
      expect(summary.existingFailedCount, 1);
      expect(summary.pendingCount, 0);
      expect(summary.unresolvedCount, 1);
    },
  );

  test(
    'does not mark transaction synced without a remote transaction ID',
    () async {
      await insertTransaction(
        localId: 'OFF-invalid-remote-id',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'items': [
            {
              'product_id': 'product-1',
              'product_name': 'Kopi',
              'quantity': 1,
              'unit_price': 1000,
              'selected_variants': const [],
            },
          ],
          'total_amount': 1000,
          'payment_method': 'CASH',
          'paid_amount': 1000,
        },
      );
      delegate.resultId = 'OFF-not-remote';

      final summary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );
      final row = await database.offlineTransactionsDao.getTransactionByLocalId(
        'OFF-invalid-remote-id',
      );

      expect(summary.stopped, isTrue);
      expect(summary.needsReconciliationCount, 1);
      expect(row?.status, 'needs_reconciliation');
      expect(row?.remoteTransactionId, isNull);
    },
  );

  test(
    'marks 400 business failures as failed and continues with next pending',
    () async {
      await insertTransaction(
        localId: 'OFF-400',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'outlet_id': 'outlet-1',
          'items': [
            {
              'product_id': 'product-1',
              'product_name': 'Kopi',
              'quantity': 1,
              'unit_price': 1000,
              'selected_variants': const [],
            },
          ],
          'total_amount': 1100,
          'service_charge': 50,
          'payment_method': 'CASH',
          'paid_amount': 1000,
        },
        receiptSnapshot: {'store_name': 'Kawula'},
      );
      delegate.failures[1] = const ApiException(
        'Stok tidak mencukupi.',
        statusCode: 400,
      );

      final summary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );
      final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      )).single;

      expect(summary.failedCount, 1);
      expect(summary.stopped, isFalse);
      expect(row.status, 'failed');
      expect(row.lastError, contains('Stok tidak mencukupi'));
    },
  );

  test('stops sync when PIN is rejected and keeps queue intact', () async {
    await insertTransaction(
      localId: 'OFF-pin',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      status: OfflineTransactionStatus.pendingSync,
      payload: {
        'outlet_id': 'outlet-1',
        'items': [
          {
            'product_id': 'product-1',
            'product_name': 'Kopi',
            'quantity': 1,
            'unit_price': 1000,
            'selected_variants': const [],
          },
        ],
        'total_amount': 1100,
        'service_charge': 50,
        'payment_method': 'CASH',
        'paid_amount': 1100,
      },
      receiptSnapshot: {'store_name': 'Kawula'},
    );
    delegate.failures[1] = const ApiException('PIN salah.', statusCode: 403);

    final summary = await service.syncOfflineTransactions(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      role: 'Kasir',
      pin: '1111',
    );
    final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
      'cashier-1',
    )).single;

    expect(summary.failedCount, 0);
    expect(summary.stopped, isTrue);
    expect(summary.stopReason, contains('PIN ditolak'));
    expect(row.status, 'pending_sync');
    expect(row.lastError, contains('PIN kasir ditolak'));
  });

  test('marks forbidden transactions failed and never retries them', () async {
    await insertTransaction(
      localId: 'OFF-forbidden',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      status: OfflineTransactionStatus.pendingSync,
      payload: {
        'outlet_id': 'outlet-1',
        'items': [
          {
            'product_id': 'product-1',
            'product_name': 'Kopi',
            'quantity': 1,
            'unit_price': 1000,
            'selected_variants': const [],
          },
        ],
        'total_amount': 1100,
        'service_charge': 50,
        'payment_method': 'CASH',
        'paid_amount': 1100,
      },
      receiptSnapshot: {'store_name': 'Kawula'},
    );
    delegate.failures[1] = const ApiException(
      'Akses ditolak oleh server.',
      statusCode: 403,
    );

    final summary = await service.syncOfflineTransactions(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      role: 'Kasir',
      pin: '1234',
    );
    final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
      'cashier-1',
    )).single;

    expect(summary.failedCount, 1);
    expect(summary.stopped, isTrue);
    expect(summary.stopReason, contains('Akses ditolak'));
    expect(row.status, 'failed');
    expect(row.lastError, contains('Akses ditolak'));

    await service.syncOfflineTransactions(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      role: 'Kasir',
      pin: '1234',
    );

    expect(delegate.calls, isEmpty);
  });

  test('stops for expired token without clearing the queue', () async {
    await insertTransaction(
      localId: 'OFF-401',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      status: OfflineTransactionStatus.pendingSync,
      payload: {
        'outlet_id': 'outlet-1',
        'items': [
          {
            'product_id': 'product-1',
            'product_name': 'Kopi',
            'quantity': 1,
            'unit_price': 1000,
            'selected_variants': const [],
          },
        ],
        'total_amount': 1100,
        'service_charge': 50,
        'payment_method': 'CASH',
        'paid_amount': 1100,
      },
      receiptSnapshot: {'store_name': 'Kawula'},
    );
    delegate.failures[1] = const ApiException('Token expired', statusCode: 401);

    final summary = await service.syncOfflineTransactions(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      role: 'Kasir',
      pin: '1234',
    );
    final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
      'cashier-1',
    )).single;

    expect(summary.stopped, isTrue);
    expect(summary.stopReason, contains('Sesi autentikasi kedaluwarsa'));
    expect(row.status, 'pending_sync');
  });

  test(
    'marks network timeout as needs_reconciliation and never auto retriggers',
    () async {
      await insertTransaction(
        localId: 'OFF-timeout',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'outlet_id': 'outlet-1',
          'items': [
            {
              'product_id': 'product-1',
              'product_name': 'Kopi',
              'quantity': 1,
              'unit_price': 1000,
              'selected_variants': const [],
            },
          ],
          'total_amount': 1100,
          'service_charge': 50,
          'payment_method': 'CASH',
          'paid_amount': 1100,
        },
        receiptSnapshot: {'store_name': 'Kawula'},
      );
      delegate.failures[1] = const SocketException('network timeout');

      final summary = await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );
      final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      )).single;

      expect(summary.needsReconciliationCount, 1);
      expect(summary.stopped, isTrue);
      expect(row.status, 'needs_reconciliation');
    },
  );
}

int insertTransactionCallCount = 0;

class _FakeCheckoutRepository implements CheckoutRepository {
  final List<String> calls = <String>[];
  final Map<int, Object> failures = <int, Object>{};
  Completer<void>? createGate;
  Completer<void>? createStarted;
  String? resultId;
  int _callCount = 0;

  @override
  Future<List<CheckoutPaymentMethod>> getPaymentMethods() async => const [];

  @override
  Future<CheckoutSettings> getSettings() async => const CheckoutSettings(
    taxPercentage: 10,
    serviceCharge: 50,
    storeName: 'Kawula',
    address: 'Jl. Utama',
  );

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
    _callCount++;
    final call = _callCount;
    createStarted?.complete();
    await createGate?.future;
    final failure = failures[call];
    if (failure != null) {
      throw failure;
    }
    final item = items.first;
    final id = resultId ?? 'server-$call';
    calls.add(item.product.id);
    return CheckoutResult(
      id: id,
      status: 'paid',
      totalAmount: estimatedTotal,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: 0,
      createdAt: DateTime.now(),
      items: [
        CheckoutResultItem(
          productName: item.product.name,
          quantity: item.quantity,
          price: item.unitPrice,
        ),
      ],
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

ActiveShift _activeShift({required String outletId}) => ActiveShift(
  id: 'server-shift',
  status: 'open',
  startTime: DateTime(2026, 11, 10),
  startingCash: 0,
  expectedCash: 0,
  totalSales: 0,
  totalTransactions: 0,
  outletId: outletId,
);
