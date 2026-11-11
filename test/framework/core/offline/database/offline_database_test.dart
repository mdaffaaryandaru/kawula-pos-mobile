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

  test('schema version one migrates to the audit table without losing transactions', () async {
    final previousWarningSetting =
        driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final directory = await Directory.systemTemp.createTemp(
      'kawula-schema-v1-migration-',
    );
    final databaseFile = File(
      '${directory.path}${Platform.pathSeparator}version-one.sqlite',
    );
    final versionOne = AppDatabase(executor: NativeDatabase(databaseFile));
    var versionOneClosed = false;
    try {
      final saved = await versionOne.offlineTransactionsDao
          .saveOfflineTransaction(
            ownerUserId: 'cashier-v1',
            outletId: 'outlet-1',
            shiftId: 'shift-1',
            transactionType: 'sale',
            payload: {'amount': 7000},
            receiptSnapshot: {'total': 7000},
          );
      await versionOne.customStatement(
        'DROP TABLE offline_transaction_resolutions',
      );
      await versionOne.customStatement('PRAGMA user_version = 1');
      await versionOne.close();
      versionOneClosed = true;

      final migrated = AppDatabase(executor: NativeDatabase(databaseFile));
      try {
        final transaction = await migrated.offlineTransactionsDao
            .getTransactionByLocalId(saved.localId);
        final audit = await migrated.offlineTransactionsDao.getResolutionAudit(
          saved.localId,
        );
        final version = await migrated
            .customSelect('PRAGMA user_version')
            .getSingle();

        expect(transaction, isNotNull);
        expect(transaction!.payloadJson, saved.payloadJson);
        expect(audit, isEmpty);
        expect(version.data['user_version'], 2);
      } finally {
        await migrated.close();
      }
    } finally {
      if (!versionOneClosed) await versionOne.close();
      await directory.delete(recursive: true);
      driftRuntimeOptions.dontWarnAboutMultipleDatabases =
          previousWarningSetting;
    }
  });
}
