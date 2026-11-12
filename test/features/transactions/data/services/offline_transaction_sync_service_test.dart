import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
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
    'syncs offline transactions in FIFO order and saves remote IDs',
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
      await insertTransaction(
        localId: 'OFF-after-400',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'items': [
            {
              'product_id': 'product-after-400',
              'product_name': 'Teh',
              'quantity': 1,
              'unit_price': 600,
            },
          ],
          'total_amount': 600,
          'payment_method': 'CASH',
          'paid_amount': 600,
        },
      );
      delegate.failures[1] = const ApiException(
        'PIN produk tidak tersedia.',
        statusCode: 400,
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

      expect(summary.failedCount, 1);
      expect(summary.successCount, 1);
      expect(summary.stopped, isFalse);
      expect(rows.first.status, 'failed');
      expect(rows.first.lastError, contains('PIN produk'));
      expect(rows.last.status, 'synced');
      expect(delegate.calls, ['product-after-400']);
    },
  );

  test(
    'fails malformed local payloads before sending and continues in FIFO order',
    () async {
      const invalidJson = '{invalid-json';
      const invalidItemsPayload = {
        'items': ['not-an-item'],
        'total_amount': 1000,
        'service_charge': 0,
        'payment_method': 'CASH',
        'paid_amount': 1000,
      };
      const invalidVariantPayload = {
        'items': [
          {
            'product_id': 'product-with-invalid-variant',
            'quantity': 1,
            'selected_variants': ['not-a-variant'],
          },
        ],
        'total_amount': 1000,
        'service_charge': 0,
        'payment_method': 'CASH',
        'paid_amount': 1000,
      };
      const invalidTotalPayload = {
        'items': [
          {
            'product_id': 'product-with-invalid-total',
            'quantity': 1,
            'selected_variants': [],
          },
        ],
        'total_amount': '1000',
        'service_charge': 0,
        'payment_method': 'CASH',
        'paid_amount': 1000,
      };
      const inconsistentPaymentPayload = {
        'items': [
          {
            'product_id': 'product-with-inconsistent-payment',
            'quantity': 1,
            'selected_variants': [],
          },
        ],
        'total_amount': 1000,
        'service_charge': 0,
        'payment_method': 'OPEN_BILL',
      };
      const invalidJsonReceipt = {'store_name': 'JSON receipt'};
      const invalidItemsReceipt = {'store_name': 'Items receipt'};
      const invalidVariantReceipt = {'store_name': 'Variant receipt'};
      const invalidTotalReceipt = {'store_name': 'Total receipt'};
      const inconsistentPaymentReceipt = {'store_name': 'Payment receipt'};

      await insertTransaction(
        localId: 'OFF-invalid-json',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        receiptSnapshot: invalidJsonReceipt,
      );
      await database.customUpdate(
        'UPDATE offline_transactions SET payload_json = ? WHERE local_id = ?',
        variables: [
          Variable.withString(invalidJson),
          Variable.withString('OFF-invalid-json'),
        ],
        updates: {database.offlineTransactions},
      );
      await insertTransaction(
        localId: 'OFF-invalid-items',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: invalidItemsPayload,
        receiptSnapshot: invalidItemsReceipt,
      );
      await insertTransaction(
        localId: 'OFF-invalid-variant',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: invalidVariantPayload,
        receiptSnapshot: invalidVariantReceipt,
      );
      await insertTransaction(
        localId: 'OFF-invalid-total',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: invalidTotalPayload,
        receiptSnapshot: invalidTotalReceipt,
      );
      await insertTransaction(
        localId: 'OFF-inconsistent-payment',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: inconsistentPaymentPayload,
        receiptSnapshot: inconsistentPaymentReceipt,
      );
      await insertTransaction(
        localId: 'OFF-after-invalid',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'items': [
            {
              'product_id': 'product-after-invalid',
              'product_name': 'Teh',
              'quantity': 1,
              'unit_price': 600,
            },
          ],
          'total_amount': 600,
          'service_charge': 0,
          'payment_method': 'CASH',
          'paid_amount': 600,
        },
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

      expect(summary.failedCount, 5);
      expect(summary.successCount, 1);
      expect(summary.stopped, isFalse);
      expect(rows.map((row) => row.status), [
        'failed',
        'failed',
        'failed',
        'failed',
        'failed',
        'synced',
      ]);
      expect(rows[0].payloadJson, invalidJson);
      expect(rows[0].lastError, contains('belum dikirim'));
      expect(rows[1].payloadJson, jsonEncode(invalidItemsPayload));
      expect(rows[1].lastError, contains('belum dikirim'));
      expect(rows[2].payloadJson, jsonEncode(invalidVariantPayload));
      expect(rows[2].lastError, contains('belum dikirim'));
      expect(rows[3].payloadJson, jsonEncode(invalidTotalPayload));
      expect(rows[3].lastError, contains('belum dikirim'));
      expect(rows[4].payloadJson, jsonEncode(inconsistentPaymentPayload));
      expect(rows[4].lastError, contains('belum dikirim'));
      expect(jsonDecode(rows[0].receiptSnapshotJson), invalidJsonReceipt);
      expect(jsonDecode(rows[1].receiptSnapshotJson), invalidItemsReceipt);
      expect(jsonDecode(rows[2].receiptSnapshotJson), invalidVariantReceipt);
      expect(jsonDecode(rows[3].receiptSnapshotJson), invalidTotalReceipt);
      expect(
        jsonDecode(rows[4].receiptSnapshotJson),
        inconsistentPaymentReceipt,
      );
      expect(delegate.calls, ['product-after-invalid']);
      expect(delegate.createTransactionCalls, 1);
    },
  );

  test('stops the batch when PIN is rejected and keeps queue intact', () async {
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
    await insertTransaction(
      localId: 'OFF-after-pin',
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      status: OfflineTransactionStatus.pendingSync,
      payload: {
        'items': [
          {
            'product_id': 'product-after-pin',
            'product_name': 'Teh',
            'quantity': 1,
            'unit_price': 600,
          },
        ],
        'total_amount': 600,
        'payment_method': 'CASH',
        'paid_amount': 600,
      },
    );
    delegate.failures[1] = const ApiException('PIN salah.', statusCode: 403);

    final summary = await service.syncOfflineTransactions(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      role: 'Kasir',
      pin: '1111',
    );
    final rows = await database.offlineTransactionsDao.getTransactionsByOwner(
      'cashier-1',
    );

    expect(summary.failedCount, 0);
    expect(summary.stopped, isTrue);
    expect(summary.stopReason, contains('PIN ditolak'));
    expect(rows.map((row) => row.status), ['pending_sync', 'pending_sync']);
    expect(rows.first.lastError, contains('PIN kasir ditolak'));
    expect(delegate.calls, isEmpty);
  });

  test(
    'marks forbidden transactions failed and stops the current batch',
    () async {
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
      await insertTransaction(
        localId: 'OFF-after-forbidden',
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        status: OfflineTransactionStatus.pendingSync,
        payload: {
          'items': [
            {
              'product_id': 'product-after-forbidden',
              'product_name': 'Teh',
              'quantity': 1,
              'unit_price': 600,
            },
          ],
          'total_amount': 600,
          'payment_method': 'CASH',
          'paid_amount': 600,
        },
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
      var rows = await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      );

      expect(summary.failedCount, 1);
      expect(summary.stopped, isTrue);
      expect(summary.stopReason, contains('Akses ditolak'));
      expect(rows.first.status, 'failed');
      expect(rows.first.lastError, contains('Akses ditolak'));
      expect(rows.last.status, 'pending_sync');
      expect(delegate.calls, isEmpty);

      await service.syncOfflineTransactions(
        ownerUserId: 'cashier-1',
        outletId: 'outlet-1',
        role: 'Kasir',
        pin: '1234',
      );

      rows = await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      );
      expect(rows.first.status, 'failed');
      expect(rows.last.status, 'synced');
      expect(delegate.calls, ['product-after-forbidden']);
    },
  );

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
  int get createTransactionCalls => _callCount;

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
