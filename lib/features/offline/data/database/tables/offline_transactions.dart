import 'package:drift/drift.dart';

@DataClassName('OfflineTransaction')
@TableIndex(
  name: 'offline_transactions_owner_status_created_idx',
  columns: {#ownerUserId, #status, #createdAtLocal},
)
@TableIndex(name: 'offline_transactions_outlet_idx', columns: {#outletId})
@TableIndex(name: 'offline_transactions_shift_idx', columns: {#shiftId})
@TableIndex(name: 'offline_transactions_status_idx', columns: {#status})
@TableIndex(
  name: 'offline_transactions_created_idx',
  columns: {#createdAtLocal},
)
class OfflineTransactions extends Table {
  TextColumn get localId => text()();

  TextColumn get ownerUserId => text()();

  TextColumn get outletId => text()();

  TextColumn get shiftId => text()();

  TextColumn get transactionType => text()();

  TextColumn get syncMarker => text().unique()();

  TextColumn get payloadJson => text()();

  TextColumn get receiptSnapshotJson => text()();

  TextColumn get status => text().withDefault(const Constant('pending_sync'))();

  TextColumn get remoteTransactionId => text().nullable()();

  DateTimeColumn get createdAtLocal => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get syncedAt => dateTime().nullable()();

  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}
