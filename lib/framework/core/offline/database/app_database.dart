import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:kawula_pos/framework/core/offline/database/daos/cached_records_dao.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';
import 'package:kawula_pos/framework/core/offline/database/tables/cached_records.dart';
import 'package:kawula_pos/framework/core/offline/database/tables/offline_transaction_resolutions.dart';
import 'package:kawula_pos/framework/core/offline/database/tables/offline_transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CachedRecords, OfflineTransactions, OfflineTransactionResolutions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor})
    : super(executor ?? driftDatabase(name: 'kawula_pos_local'));

  late final CachedRecordsDao cachedRecordsDao = CachedRecordsDao(this);
  late final OfflineTransactionsDao offlineTransactionsDao =
      OfflineTransactionsDao(this);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from == 0 && to >= 1) {
        await migrator.createAll();
        return;
      }

      if (from == 1 && to >= 2) {
        await migrator.createTable(offlineTransactionResolutions);
        await migrator.createIndex(
          offlineTransactionResolutionsLocalCreatedIdx,
        );
        return;
      }

      throw StateError(
        'Migrasi database dari versi $from ke $to belum tersedia.',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
