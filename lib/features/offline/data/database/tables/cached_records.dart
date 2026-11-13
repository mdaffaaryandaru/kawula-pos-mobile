import 'package:drift/drift.dart';

@DataClassName('CachedRecord')
class CachedRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cacheType => text()();
  TextColumn get cacheKey => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {cacheType, cacheKey},
  ];
}
