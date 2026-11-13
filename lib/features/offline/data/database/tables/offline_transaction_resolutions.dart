import 'package:drift/drift.dart';

@DataClassName('OfflineTransactionResolution')
@TableIndex(
  name: 'offline_transaction_resolutions_local_created_idx',
  columns: {#localId, #resolvedAt},
)
class OfflineTransactionResolutions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get localId => text()();

  TextColumn get outletId => text()();

  TextColumn get previousStatus => text()();

  TextColumn get resultingStatus => text()();

  TextColumn get resolutionType => text()();

  TextColumn get remoteTransactionId => text().nullable()();

  TextColumn get resolvingAdminUserId => text()();

  TextColumn get resolvingAdminRole => text()();

  DateTimeColumn get resolvedAt => dateTime()();

  TextColumn get reason => text()();

  TextColumn get notes => text().nullable()();
}
