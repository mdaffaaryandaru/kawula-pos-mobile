import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/cached_records_dao.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';

void main() {
  late AppDatabase database;
  late CachedRecordsDao cachedRecordsDao;
  late OfflineTransactionsDao offlineTransactionsDao;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    cachedRecordsDao = database.cachedRecordsDao;
    offlineTransactionsDao = database.offlineTransactionsDao;
  });

  tearDown(() async {
    await database.close();
  });

  Future<OfflineTransaction> saveTransaction({
    String ownerUserId = 'cashier-a',
    String outletId = 'outlet-1',
    String shiftId = 'shift-1',
    DateTime? createdAtLocal,
    Object? receiptSnapshot = const {'total': 12000},
    OfflineTransactionStatus status = OfflineTransactionStatus.pendingSync,
    String? lastError,
  }) {
    return offlineTransactionsDao.saveOfflineTransaction(
      ownerUserId: ownerUserId,
      outletId: outletId,
      shiftId: shiftId,
      transactionType: 'sale',
      payload: const {
        'items': [
          {'product_id': 'product-1', 'quantity': 1},
        ],
        'amount': 12000,
      },
      receiptSnapshot: receiptSnapshot,
      createdAtLocal: createdAtLocal,
      status: status,
      lastError: lastError,
    );
  }

  group('local cache', () {
    test('database opens and initializes the current schema version', () async {
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();

      expect(version.data['user_version'], 2);
      expect(await cachedRecordsDao.getCachesByType('products'), isEmpty);
      final tables = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      expect(
        tables.map((row) => row.data['name']).toSet(),
        containsAll([
          'cached_records',
          'offline_transactions',
          'offline_transaction_resolutions',
        ]),
      );
      final indexes = await database
          .customSelect("PRAGMA index_list('offline_transactions')")
          .get();
      expect(
        indexes.map((row) => row.data['name']),
        containsAll([
          'offline_transactions_owner_status_created_idx',
          'offline_transactions_outlet_idx',
          'offline_transactions_shift_idx',
          'offline_transactions_status_idx',
          'offline_transactions_created_idx',
        ]),
      );
      expect(
        await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name = 'offline_transaction_resolutions_local_created_idx'",
            )
            .getSingleOrNull(),
        isNotNull,
      );
    });

    test(
      'initializes a version-zero database without losing existing rows',
      () async {
        final previousWarningSetting =
            driftRuntimeOptions.dontWarnAboutMultipleDatabases;
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        final directory = await Directory.systemTemp.createTemp(
          'kawula-schema-migration-',
        );
        final databaseFile = File(
          '${directory.path}${Platform.pathSeparator}legacy.sqlite',
        );
        AppDatabase? migrationDatabase;

        try {
          migrationDatabase = AppDatabase(
            executor: NativeDatabase(
              databaseFile,
              setup: (rawDatabase) {
                rawDatabase.execute(
                  'CREATE TABLE legacy_marker (value TEXT NOT NULL)',
                );
                rawDatabase.execute(
                  "INSERT INTO legacy_marker (value) VALUES ('preserved')",
                );
              },
            ),
          );

          final version = await migrationDatabase
              .customSelect('PRAGMA user_version')
              .getSingle();
          final marker = await migrationDatabase
              .customSelect('SELECT value FROM legacy_marker')
              .getSingle();

          expect(version.data['user_version'], 2);
          expect(marker.data['value'], 'preserved');
          expect(
            await migrationDatabase.cachedRecordsDao.getCachesByType(
              'products',
            ),
            isEmpty,
          );
        } finally {
          await migrationDatabase?.close();
          await directory.delete(recursive: true);
          driftRuntimeOptions.dontWarnAboutMultipleDatabases =
              previousWarningSetting;
        }
      },
    );

    test('saves and reads cache payload by type and key', () async {
      await cachedRecordsDao.saveCache(
        cacheType: 'products',
        cacheKey: 'outlet-1',
        payload: [
          {'id': 'product-1', 'name': 'Kopi'},
        ],
      );

      final record = await cachedRecordsDao.getCache('products', 'outlet-1');

      expect(jsonDecode(record!.payloadJson), [
        {'id': 'product-1', 'name': 'Kopi'},
      ]);
    });

    test('updating the same cache key does not create duplicates', () async {
      await cachedRecordsDao.saveCache(
        cacheType: 'products',
        cacheKey: 'outlet-1',
        payload: {'version': 1},
        updatedAt: DateTime.utc(2026, 11, 8),
      );
      await cachedRecordsDao.saveCache(
        cacheType: 'products',
        cacheKey: 'outlet-1',
        payload: {'version': 2},
        updatedAt: DateTime.utc(2026, 11, 9),
      );

      final records = await cachedRecordsDao.getCachesByType('products');

      expect(records, hasLength(1));
      expect(jsonDecode(records.single.payloadJson), {'version': 2});
      expect(
        records.single.updatedAt.millisecondsSinceEpoch,
        DateTime.utc(2026, 11, 9).millisecondsSinceEpoch,
      );
    });

    test('updates timestamp and deletes a cache record', () async {
      final updatedAt = DateTime.utc(2026, 11, 9);
      await cachedRecordsDao.saveCache(
        cacheType: 'outlet',
        cacheKey: 'outlet-1',
        payload: {'name': 'Kawula'},
        updatedAt: updatedAt,
      );

      final updatedRecord = await cachedRecordsDao.getCache(
        'outlet',
        'outlet-1',
      );
      final deleted = await cachedRecordsDao.deleteCache('outlet', 'outlet-1');

      expect(
        updatedRecord!.updatedAt.millisecondsSinceEpoch,
        updatedAt.millisecondsSinceEpoch,
      );
      expect(deleted, isTrue);
      expect(await cachedRecordsDao.getCache('outlet', 'outlet-1'), isNull);
    });

    test('rejects credentials in cache payloads', () async {
      await expectLater(
        cachedRecordsDao.saveCache(
          cacheType: 'profile',
          cacheKey: 'cashier-1',
          payload: {
            'profile': {'name': 'Kasir'},
            'access_token': 'do-not-store',
          },
        ),
        throwsArgumentError,
      );
    });
  });

  group('offline transaction queue', () {
    test('saves transaction and full receipt snapshot atomically', () async {
      final snapshot = {
        'items': [
          {'name': 'Kopi', 'quantity': 2, 'price': 12000},
        ],
        'total': 24000,
        'footer': 'Terima kasih',
      };
      final transaction = await saveTransaction(receiptSnapshot: snapshot);

      expect(transaction.localId, startsWith('OFF-'));
      expect(
        transaction.status,
        OfflineTransactionStatus.pendingSync.databaseValue,
      );
      expect(jsonDecode(transaction.receiptSnapshotJson), snapshot);
    });

    test('generates unique local IDs and sync markers', () async {
      final first = await saveTransaction();
      final second = await saveTransaction();

      expect(first.localId, isNot(second.localId));
      expect(first.syncMarker, isNot(second.syncMarker));
    });

    test('database rejects a duplicate sync marker', () async {
      final original = await saveTransaction();
      final createdAt = DateTime.utc(2026, 11, 9);

      await expectLater(
        database
            .into(database.offlineTransactions)
            .insert(
              OfflineTransactionsCompanion.insert(
                localId: 'OFF-duplicate-marker-test',
                ownerUserId: original.ownerUserId,
                outletId: original.outletId,
                shiftId: original.shiftId,
                transactionType: original.transactionType,
                syncMarker: original.syncMarker,
                payloadJson: original.payloadJson,
                receiptSnapshotJson: original.receiptSnapshotJson,
                createdAtLocal: createdAt,
                updatedAt: createdAt,
              ),
            ),
        throwsA(anything),
      );
    });

    test(
      'returns owner queues in FIFO order with a stable tie breaker',
      () async {
        final createdAt = DateTime.utc(2026, 11, 9, 8);
        final newer = await saveTransaction(
          ownerUserId: 'cashier-a',
          createdAtLocal: createdAt.add(const Duration(minutes: 2)),
        );
        final older = await saveTransaction(
          ownerUserId: 'cashier-a',
          createdAtLocal: createdAt,
        );
        final sameTime = await saveTransaction(
          ownerUserId: 'cashier-a',
          createdAtLocal: createdAt,
        );
        await saveTransaction(ownerUserId: 'cashier-b');

        final queue = await offlineTransactionsDao.getFifoQueue(
          ownerUserId: 'cashier-a',
          statuses: const [OfflineTransactionStatus.pendingSync],
        );
        final ownerTransactions = await offlineTransactionsDao
            .getTransactionsByOwner('cashier-a');

        final sameTimestampIds = [older.localId, sameTime.localId]..sort();
        expect(queue.map((item) => item.localId), [
          ...sameTimestampIds,
          newer.localId,
        ]);
        expect(ownerTransactions, hasLength(3));
      },
    );

    test('filters transactions by status and owner', () async {
      final failed = await saveTransaction(ownerUserId: 'cashier-a');
      await saveTransaction(ownerUserId: 'cashier-b');
      await offlineTransactionsDao.updateSyncStatus(
        localId: failed.localId,
        status: OfflineTransactionStatus.failed,
        lastError: 'Network unavailable',
      );

      final transactions = await offlineTransactionsDao.getTransactionsByStatus(
        OfflineTransactionStatus.failed,
        ownerUserId: 'cashier-a',
      );

      expect(transactions.map((item) => item.localId), [failed.localId]);
    });

    test('unresolved shift queue includes all blocking statuses and isolates user, outlet, and shift', () async {
      for (final status in [
        OfflineTransactionStatus.pendingSync,
        OfflineTransactionStatus.syncing,
        OfflineTransactionStatus.failed,
        OfflineTransactionStatus.needsReconciliation,
      ]) {
        await saveTransaction(
          ownerUserId: 'cashier-a',
          outletId: 'outlet-1',
          shiftId: 'shift-1',
          status: status,
          lastError: status == OfflineTransactionStatus.failed
              ? 'Business rejection'
              : null,
        );
      }
      await saveTransaction(
        ownerUserId: 'cashier-a',
        outletId: 'outlet-1',
        shiftId: 'shift-1',
        status: OfflineTransactionStatus.synced,
      );
      await saveTransaction(
        ownerUserId: 'cashier-a',
        outletId: 'outlet-1',
        shiftId: 'shift-1',
        status: OfflineTransactionStatus.resolvedManually,
      );
      await saveTransaction(ownerUserId: 'cashier-b');
      await saveTransaction(ownerUserId: 'cashier-a', outletId: 'outlet-2');
      await saveTransaction(ownerUserId: 'cashier-a', shiftId: 'shift-2');

      final unresolved = await offlineTransactionsDao.getUnresolvedTransactions(
        ownerUserId: 'cashier-a',
        outletId: 'outlet-1',
        shiftId: 'shift-1',
      );

      expect(unresolved, hasLength(4));
      expect(unresolved.map((record) => record.status).toSet(), {
        'pending_sync',
        'syncing',
        'failed',
        'needs_reconciliation',
      });
    });

    test('updates sync status, server ID, and attempt count', () async {
      final saved = await saveTransaction();
      await offlineTransactionsDao.updateSyncStatus(
        localId: saved.localId,
        status: OfflineTransactionStatus.syncing,
      );
      await offlineTransactionsDao.updateSyncStatus(
        localId: saved.localId,
        status: OfflineTransactionStatus.synced,
        remoteTransactionId: 'server-transaction-1',
      );

      final updated = await offlineTransactionsDao.getTransactionByLocalId(
        saved.localId,
      );

      expect(updated!.status, OfflineTransactionStatus.synced.databaseValue);
      expect(updated.remoteTransactionId, 'server-transaction-1');
      expect(updated.attemptCount, 1);
      expect(updated.syncedAt, isNotNull);
    });

    test('keeps failed transactions and stores their failure reason', () async {
      final saved = await saveTransaction();
      await offlineTransactionsDao.updateSyncStatus(
        localId: saved.localId,
        status: OfflineTransactionStatus.syncing,
      );
      await offlineTransactionsDao.updateSyncStatus(
        localId: saved.localId,
        status: OfflineTransactionStatus.failed,
        lastError: 'Server rejected the transaction',
      );

      final failed = await offlineTransactionsDao.getTransactionByLocalId(
        saved.localId,
      );

      expect(failed, isNotNull);
      expect(failed!.status, OfflineTransactionStatus.failed.databaseValue);
      expect(failed.lastError, 'Server rejected the transaction');
      expect(failed.attemptCount, 1);
    });

    test(
      'manual resolution is audited and does not erase transaction evidence',
      () async {
        final saved = await saveTransaction(
          status: OfflineTransactionStatus.needsReconciliation,
          lastError: 'Server response was lost',
        );
        final resolvedAt = DateTime.utc(2026, 11, 10, 12);

        final resolved = await offlineTransactionsDao.resolveManually(
          localId: saved.localId,
          outletId: 'outlet-1',
          adminUserId: 'admin-1',
          adminRole: 'Admin',
          resolutionType: 'matched_existing_remote',
          remoteTransactionId: 'server-transaction-1',
          resolvedAt: resolvedAt,
          reason: 'Confirmed against server history.',
          notes: 'Two products and local receipt reviewed.',
        );
        final transaction = await offlineTransactionsDao
            .getTransactionByLocalId(saved.localId);
        final audit = await offlineTransactionsDao.getResolutionAudit(
          saved.localId,
        );
        final unresolved = await offlineTransactionsDao
            .getUnresolvedTransactions(
              ownerUserId: 'cashier-a',
              outletId: 'outlet-1',
              shiftId: 'shift-1',
            );

        expect(resolved, isTrue);
        expect(transaction!.status, 'resolved_manually');
        expect(transaction.remoteTransactionId, 'server-transaction-1');
        expect(transaction.lastError, 'Server response was lost');
        expect(transaction.payloadJson, saved.payloadJson);
        expect(transaction.receiptSnapshotJson, saved.receiptSnapshotJson);
        expect(transaction.syncedAt, isNull);
        expect(audit, hasLength(1));
        expect(audit.single.previousStatus, 'needs_reconciliation');
        expect(audit.single.resultingStatus, 'resolved_manually');
        expect(audit.single.resolvingAdminUserId, 'admin-1');
        expect(audit.single.resolutionType, 'matched_existing_remote');
        expect(audit.single.reason, 'Confirmed against server history.');
        expect(audit.single.notes, 'Two products and local receipt reviewed.');
        expect(
          audit.single.resolvedAt.millisecondsSinceEpoch,
          resolvedAt.millisecondsSinceEpoch,
        );
        expect(unresolved, isEmpty);
      },
    );

    test(
      'manual handling outside server cannot resolve unknown outcomes',
      () async {
        final saved = await saveTransaction(
          status: OfflineTransactionStatus.needsReconciliation,
        );

        await expectLater(
          offlineTransactionsDao.resolveManually(
            localId: saved.localId,
            outletId: 'outlet-1',
            adminUserId: 'admin-1',
            adminRole: 'Admin',
            resolutionType: 'handled_outside_server',
            resolvedAt: DateTime.utc(2026, 11, 10),
            reason: 'Cannot verify server state.',
          ),
          throwsStateError,
        );

        expect(
          (await offlineTransactionsDao.getTransactionByLocalId(saved.localId))!
              .status,
          'needs_reconciliation',
        );
        expect(
          await offlineTransactionsDao.getResolutionAudit(saved.localId),
          isEmpty,
        );
      },
    );

    test(
      'outlet queue query includes all owners and excludes other outlets',
      () async {
        final local = await saveTransaction(
          ownerUserId: 'cashier-a',
          outletId: 'outlet-1',
        );
        final sameOutlet = await saveTransaction(
          ownerUserId: 'cashier-b',
          outletId: 'outlet-1',
        );
        await saveTransaction(ownerUserId: 'cashier-c', outletId: 'outlet-2');

        final records = await offlineTransactionsDao.getTransactionsByOutlet(
          outletId: 'outlet-1',
        );

        expect(records.map((record) => record.localId).toSet(), {
          local.localId,
          sameOutlet.localId,
        });
      },
    );
  });

  test(
    'transaction remains after closing and reopening a file database',
    () async {
      final previousWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final directory = await Directory.systemTemp.createTemp(
        'kawula-offline-db-',
      );
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}test.sqlite',
      );
      final persistentDatabase = AppDatabase(
        executor: NativeDatabase(databaseFile),
      );
      final saved = await persistentDatabase.offlineTransactionsDao
          .saveOfflineTransaction(
            ownerUserId: 'cashier-persist',
            outletId: 'outlet-1',
            shiftId: 'shift-1',
            transactionType: 'sale',
            payload: {'amount': 5000},
            receiptSnapshot: {'total': 5000},
          );
      await persistentDatabase.close();

      final reopenedDatabase = AppDatabase(
        executor: NativeDatabase(databaseFile),
      );
      try {
        final restored = await reopenedDatabase.offlineTransactionsDao
            .getTransactionByLocalId(saved.localId);
        expect(restored, isNotNull);
        expect(restored!.payloadJson, saved.payloadJson);
        expect(restored.receiptSnapshotJson, saved.receiptSnapshotJson);
      } finally {
        await reopenedDatabase.close();
        await directory.delete(recursive: true);
        driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarningSetting;
      }
    },
  );

  test(
    'resolution audit remains after closing and reopening the database',
    () async {
      final previousWarningSetting =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final directory = await Directory.systemTemp.createTemp(
        'kawula-resolution-audit-',
      );
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}audit.sqlite',
      );
      final persistentDatabase = AppDatabase(
        executor: NativeDatabase(databaseFile),
      );
      var databaseClosed = false;
      try {
        final saved = await persistentDatabase.offlineTransactionsDao
            .saveOfflineTransaction(
              ownerUserId: 'cashier-persist',
              outletId: 'outlet-1',
              shiftId: 'shift-1',
              transactionType: 'sale',
              payload: {'total_amount': 5000},
              receiptSnapshot: {'total_amount': 5000},
              status: OfflineTransactionStatus.failed,
              lastError: 'Server rejected transaction',
            );
        await persistentDatabase.offlineTransactionsDao.resolveManually(
          localId: saved.localId,
          outletId: 'outlet-1',
          adminUserId: 'admin-1',
          adminRole: 'Admin',
          resolutionType: 'handled_outside_server',
          resolvedAt: DateTime.utc(2026, 11, 10),
          reason: 'Handled by the store manager.',
        );
        await persistentDatabase.close();
        databaseClosed = true;

        final reopenedDatabase = AppDatabase(
          executor: NativeDatabase(databaseFile),
        );
        try {
          final transaction = await reopenedDatabase.offlineTransactionsDao
              .getTransactionByLocalId(saved.localId);
          final audit = await reopenedDatabase.offlineTransactionsDao
              .getResolutionAudit(saved.localId);

          expect(transaction!.status, 'resolved_manually');
          expect(transaction.remoteTransactionId, isNull);
          expect(audit, hasLength(1));
          expect(audit.single.resolutionType, 'handled_outside_server');
        } finally {
          await reopenedDatabase.close();
        }
      } finally {
        if (!databaseClosed) await persistentDatabase.close();
        await directory.delete(recursive: true);
        driftRuntimeOptions.dontWarnAboutMultipleDatabases =
            previousWarningSetting;
      }
    },
  );

  test('schema version one migrates all cache and transaction data to version two', () async {
    final previousWarningSetting =
        driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final directory = await Directory.systemTemp.createTemp(
      'kawula-schema-v1-migration-',
    );
    final databaseFile = File(
      '${directory.path}${Platform.pathSeparator}version-one.sqlite',
    );
    final cacheRows = [
      (
        id: 101,
        type: 'products',
        key: 'outlet-1',
        payload: '{"items":[{"id":"product-1","name":"Kopi"}]}',
        updatedAt: DateTime.utc(2026, 11, 8, 10),
      ),
      (
        id: 102,
        type: 'categories',
        key: 'outlet-1',
        payload: '{"items":[{"id":"category-1","name":"Minuman"}]}',
        updatedAt: DateTime.utc(2026, 11, 8, 11),
      ),
      (
        id: 103,
        type: 'checkout_settings',
        key: 'outlet-1',
        payload: '{"tax_percentage":10,"service_charge":2000}',
        updatedAt: DateTime.utc(2026, 11, 8, 12),
      ),
    ];
    final transactionRows = [
      (
        localId: 'OFF-v1-pending',
        owner: 'cashier-v1',
        outlet: 'outlet-1',
        shift: 'shift-v1',
        type: 'sale',
        marker: 'marker-v1-pending',
        payload: '{"total_amount":1000,"payment_method":"CASH"}',
        receipt: '{"transaction_id":"OFF-v1-pending","total_amount":1000}',
        status: 'pending_sync',
        remoteId: null,
        createdAt: DateTime.utc(2026, 11, 9, 8),
        updatedAt: DateTime.utc(2026, 11, 9, 8, 1),
        syncedAt: null,
        attemptCount: 0,
        lastError: null,
      ),
      (
        localId: 'OFF-v1-failed',
        owner: 'cashier-v1',
        outlet: 'outlet-1',
        shift: 'shift-v1',
        type: 'sale',
        marker: 'marker-v1-failed',
        payload: '{"total_amount":2000,"payment_method":"CARD"}',
        receipt: '{"transaction_id":"OFF-v1-failed","total_amount":2000}',
        status: 'failed',
        remoteId: null,
        createdAt: DateTime.utc(2026, 11, 9, 9),
        updatedAt: DateTime.utc(2026, 11, 9, 9, 1),
        syncedAt: null,
        attemptCount: 2,
        lastError: 'Business rejection',
      ),
      (
        localId: 'OFF-v1-reconciliation',
        owner: 'cashier-v1',
        outlet: 'outlet-2',
        shift: 'shift-v2',
        type: 'open_bill',
        marker: 'marker-v1-reconciliation',
        payload: '{"total_amount":3000,"payment_method":"OPEN_BILL"}',
        receipt:
            '{"transaction_id":"OFF-v1-reconciliation","total_amount":3000}',
        status: 'needs_reconciliation',
        remoteId: null,
        createdAt: DateTime.utc(2026, 11, 9, 10),
        updatedAt: DateTime.utc(2026, 11, 9, 10, 1),
        syncedAt: null,
        attemptCount: 1,
        lastError: 'Response status unknown',
      ),
      (
        localId: 'OFF-v1-synced',
        owner: 'cashier-v1',
        outlet: 'outlet-1',
        shift: 'shift-v1',
        type: 'sale',
        marker: 'marker-v1-synced',
        payload: '{"total_amount":4000,"payment_method":"CASH"}',
        receipt: '{"transaction_id":"OFF-v1-synced","total_amount":4000}',
        status: 'synced',
        remoteId: 'remote-v1-synced',
        createdAt: DateTime.utc(2026, 11, 9, 11),
        updatedAt: DateTime.utc(2026, 11, 9, 11, 1),
        syncedAt: DateTime.utc(2026, 11, 9, 11, 2),
        attemptCount: 1,
        lastError: null,
      ),
    ];

    final fixture = AppDatabase(
      executor: NativeDatabase(
        databaseFile,
        setup: (rawDatabase) {
          rawDatabase.execute('''
            CREATE TABLE cached_records (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              cache_type TEXT NOT NULL,
              cache_key TEXT NOT NULL,
              payload_json TEXT NOT NULL,
              updated_at INTEGER NOT NULL,
              UNIQUE (cache_type, cache_key)
            )
          ''');
          rawDatabase.execute('''
            CREATE TABLE offline_transactions (
              local_id TEXT NOT NULL PRIMARY KEY,
              owner_user_id TEXT NOT NULL,
              outlet_id TEXT NOT NULL,
              shift_id TEXT NOT NULL,
              transaction_type TEXT NOT NULL,
              sync_marker TEXT NOT NULL UNIQUE,
              payload_json TEXT NOT NULL,
              receipt_snapshot_json TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending_sync',
              remote_transaction_id TEXT,
              created_at_local INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              synced_at INTEGER,
              attempt_count INTEGER NOT NULL DEFAULT 0,
              last_error TEXT
            )
          ''');
          rawDatabase.execute(
            'CREATE INDEX offline_transactions_owner_status_created_idx '
            'ON offline_transactions (owner_user_id, status, created_at_local)',
          );
          rawDatabase.execute(
            'CREATE INDEX offline_transactions_outlet_idx '
            'ON offline_transactions (outlet_id)',
          );
          rawDatabase.execute(
            'CREATE INDEX offline_transactions_shift_idx '
            'ON offline_transactions (shift_id)',
          );
          rawDatabase.execute(
            'CREATE INDEX offline_transactions_status_idx '
            'ON offline_transactions (status)',
          );
          rawDatabase.execute(
            'CREATE INDEX offline_transactions_created_idx '
            'ON offline_transactions (created_at_local)',
          );

          for (final cache in cacheRows) {
            rawDatabase.execute(
              'INSERT INTO cached_records '
              '(id, cache_type, cache_key, payload_json, updated_at) '
              'VALUES (?, ?, ?, ?, ?)',
              [
                cache.id,
                cache.type,
                cache.key,
                cache.payload,
                cache.updatedAt.millisecondsSinceEpoch ~/ 1000,
              ],
            );
          }
          for (final record in transactionRows) {
            rawDatabase.execute(
              'INSERT INTO offline_transactions ('
              'local_id, owner_user_id, outlet_id, shift_id, transaction_type, '
              'sync_marker, payload_json, receipt_snapshot_json, status, '
              'remote_transaction_id, created_at_local, updated_at, synced_at, '
              'attempt_count, last_error) '
              'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
              [
                record.localId,
                record.owner,
                record.outlet,
                record.shift,
                record.type,
                record.marker,
                record.payload,
                record.receipt,
                record.status,
                record.remoteId,
                record.createdAt.millisecondsSinceEpoch ~/ 1000,
                record.updatedAt.millisecondsSinceEpoch ~/ 1000,
                record.syncedAt == null
                    ? null
                    : record.syncedAt!.millisecondsSinceEpoch ~/ 1000,
                record.attemptCount,
                record.lastError,
              ],
            );
          }
          rawDatabase.execute('PRAGMA user_version = 1');
        },
      ),
    );
    await fixture.customSelect('PRAGMA user_version').getSingle();
    await fixture.close();

    var migratedClosed = false;
    try {
      var migrated = AppDatabase(executor: NativeDatabase(databaseFile));
      try {
        final version = await migrated
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 2);

        final tables = await migrated
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get();
        expect(
          tables.map((row) => row.data['name']).toSet(),
          containsAll([
            'cached_records',
            'offline_transactions',
            'offline_transaction_resolutions',
          ]),
        );

        final caches = <CachedRecord>[];
        for (final cache in cacheRows) {
          final row = await migrated.cachedRecordsDao.getCache(
            cache.type,
            cache.key,
          );
          expect(row, isNotNull);
          caches.add(row!);
          expect(row.id, cache.id);
          expect(row.payloadJson, cache.payload);
          expect(
            row.updatedAt.millisecondsSinceEpoch,
            cache.updatedAt.millisecondsSinceEpoch,
          );
        }
        expect(caches, hasLength(3));

        final transactions = await migrated.offlineTransactionsDao
            .getTransactionsByOwner('cashier-v1');
        expect(transactions, hasLength(transactionRows.length));
        for (final expected in transactionRows) {
          final actual = transactions.singleWhere(
            (record) => record.localId == expected.localId,
          );
          expect(actual.ownerUserId, expected.owner);
          expect(actual.outletId, expected.outlet);
          expect(actual.shiftId, expected.shift);
          expect(actual.transactionType, expected.type);
          expect(actual.syncMarker, expected.marker);
          expect(actual.payloadJson, expected.payload);
          expect(actual.receiptSnapshotJson, expected.receipt);
          expect(actual.status, expected.status);
          expect(actual.remoteTransactionId, expected.remoteId);
          expect(
            actual.createdAtLocal.millisecondsSinceEpoch,
            expected.createdAt.millisecondsSinceEpoch,
          );
          expect(
            actual.updatedAt.millisecondsSinceEpoch,
            expected.updatedAt.millisecondsSinceEpoch,
          );
          expect(
            actual.syncedAt?.millisecondsSinceEpoch,
            expected.syncedAt?.millisecondsSinceEpoch,
          );
          expect(actual.attemptCount, expected.attemptCount);
          expect(actual.lastError, expected.lastError);
        }

        final cacheIndexes = await migrated
            .customSelect("PRAGMA index_list('cached_records')")
            .get();
        expect(cacheIndexes.any((row) => row.data['unique'] == 1), isTrue);
        final cacheUniqueIndex = cacheIndexes.firstWhere(
          (row) => row.data['unique'] == 1,
        );
        final cacheIndexColumns = await migrated
            .customSelect(
              "PRAGMA index_info('${cacheUniqueIndex.data['name']}')",
            )
            .get();
        expect(cacheIndexColumns.map((row) => row.data['name']).toList(), [
          'cache_type',
          'cache_key',
        ]);

        final transactionIndexes = await migrated
            .customSelect("PRAGMA index_list('offline_transactions')")
            .get();
        final transactionIndexNames = transactionIndexes
            .map((row) => row.data['name'])
            .toSet();
        expect(
          transactionIndexNames,
          containsAll([
            'offline_transactions_owner_status_created_idx',
            'offline_transactions_outlet_idx',
            'offline_transactions_shift_idx',
            'offline_transactions_status_idx',
            'offline_transactions_created_idx',
          ]),
        );
        expect(
          transactionIndexes.any((row) => row.data['unique'] == 1),
          isTrue,
        );
        var hasUniqueSyncMarker = false;
        for (final index in transactionIndexes.where(
          (row) => row.data['unique'] == 1,
        )) {
          final columns = await migrated
              .customSelect("PRAGMA index_info('${index.data['name']}')")
              .get();
          if (columns.length == 1 &&
              columns.single.data['name'] == 'sync_marker') {
            hasUniqueSyncMarker = true;
          }
        }
        expect(hasUniqueSyncMarker, isTrue);
        final transactionColumns = await migrated
            .customSelect("PRAGMA table_info('offline_transactions')")
            .get();
        expect(
          transactionColumns
              .singleWhere((row) => row.data['name'] == 'local_id')
              .data['pk'],
          1,
        );
        expect(
          transactionColumns
              .singleWhere((row) => row.data['name'] == 'status')
              .data['dflt_value'],
          "'pending_sync'",
        );
        expect(
          transactionColumns
              .singleWhere((row) => row.data['name'] == 'attempt_count')
              .data['dflt_value'],
          '0',
        );

        final resolutionIndexes = await migrated
            .customSelect(
              "PRAGMA index_list('offline_transaction_resolutions')",
            )
            .get();
        expect(
          resolutionIndexes.map((row) => row.data['name']),
          contains('offline_transaction_resolutions_local_created_idx'),
        );

        final linked = transactions.firstWhere(
          (record) => record.status == 'needs_reconciliation',
        );
        final auditInserted = await migrated.offlineTransactionsDao
            .resolveManually(
              localId: linked.localId,
              outletId: linked.outletId,
              adminUserId: 'admin-v2',
              adminRole: 'Admin',
              resolutionType: 'matched_existing_remote',
              remoteTransactionId: 'remote-after-migration',
              resolvedAt: DateTime.utc(2026, 11, 10, 12),
              reason: 'Linked after migration.',
            );
        expect(auditInserted, isTrue);
        final linkedAudit = await migrated.offlineTransactionsDao
            .getResolutionAudit(linked.localId);
        expect(linkedAudit, hasLength(1));
        expect(linkedAudit.single.localId, linked.localId);
        expect(
          linkedAudit.single.remoteTransactionId,
          'remote-after-migration',
        );
        await migrated.close();
        migratedClosed = true;
      } finally {
        if (!migratedClosed) await migrated.close();
      }

      final reopened = AppDatabase(executor: NativeDatabase(databaseFile));
      try {
        final transactions = await reopened.offlineTransactionsDao
            .getTransactionsByOwner('cashier-v1');
        expect(transactions, hasLength(transactionRows.length));
        for (final expected in transactionRows) {
          final actual = transactions.singleWhere(
            (record) => record.localId == expected.localId,
          );
          final wasLinked = expected.localId == 'OFF-v1-reconciliation';
          expect(actual.ownerUserId, expected.owner);
          expect(actual.outletId, expected.outlet);
          expect(actual.shiftId, expected.shift);
          expect(actual.transactionType, expected.type);
          expect(actual.syncMarker, expected.marker);
          expect(actual.payloadJson, expected.payload);
          expect(actual.receiptSnapshotJson, expected.receipt);
          expect(
            actual.status,
            wasLinked ? 'resolved_manually' : expected.status,
          );
          expect(
            actual.remoteTransactionId,
            wasLinked ? 'remote-after-migration' : expected.remoteId,
          );
          expect(actual.attemptCount, expected.attemptCount);
          expect(actual.lastError, expected.lastError);
          expect(
            actual.createdAtLocal.millisecondsSinceEpoch,
            expected.createdAt.millisecondsSinceEpoch,
          );
          expect(
            actual.updatedAt.millisecondsSinceEpoch,
            wasLinked
                ? DateTime.utc(2026, 11, 10, 12).millisecondsSinceEpoch
                : expected.updatedAt.millisecondsSinceEpoch,
          );
          expect(
            actual.syncedAt?.millisecondsSinceEpoch,
            expected.syncedAt?.millisecondsSinceEpoch,
          );
        }
        final linked = transactions.singleWhere(
          (record) => record.localId == 'OFF-v1-reconciliation',
        );
        expect(
          await reopened.offlineTransactionsDao.getResolutionAudit(
            linked.localId,
          ),
          hasLength(1),
        );
        for (final cache in cacheRows) {
          final row = await reopened.cachedRecordsDao.getCache(
            cache.type,
            cache.key,
          );
          expect(row, isNotNull);
          expect(row!.id, cache.id);
          expect(row.payloadJson, cache.payload);
          expect(
            row.updatedAt.millisecondsSinceEpoch,
            cache.updatedAt.millisecondsSinceEpoch,
          );
        }
      } finally {
        await reopened.close();
      }
    } finally {
      await directory.delete(recursive: true);
      driftRuntimeOptions.dontWarnAboutMultipleDatabases =
          previousWarningSetting;
    }
  });
}
