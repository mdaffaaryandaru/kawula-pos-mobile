import 'package:drift/drift.dart';

import 'package:kawula_pos/features/offline/data/database/app_database.dart';
import 'package:kawula_pos/features/offline/data/database/json_payload.dart';

class CachedRecordsDao extends DatabaseAccessor<AppDatabase> {
  CachedRecordsDao(super.database) : _database = database;

  final AppDatabase _database;

  Future<CachedRecord?> getCache(String cacheType, String cacheKey) {
    return (select(_database.cachedRecords)..where(
          (record) =>
              record.cacheType.equals(cacheType) &
              record.cacheKey.equals(cacheKey),
        ))
        .getSingleOrNull();
  }

  Future<List<CachedRecord>> getCachesByType(String cacheType) {
    return (select(_database.cachedRecords)
          ..where((record) => record.cacheType.equals(cacheType))
          ..orderBy([(record) => OrderingTerm.asc(record.cacheKey)]))
        .get();
  }

  Future<CachedRecord> saveCache({
    required String cacheType,
    required String cacheKey,
    required Object? payload,
    DateTime? updatedAt,
  }) async {
    _validateKey(cacheType, 'cacheType');
    _validateKey(cacheKey, 'cacheKey');
    final payloadJson = encodeJsonWithoutCredentials(payload);

    return transaction(() async {
      final existing =
          await (select(_database.cachedRecords)..where(
                (record) =>
                    record.cacheType.equals(cacheType) &
                    record.cacheKey.equals(cacheKey),
              ))
              .getSingleOrNull();
      if (existing == null) {
        await into(_database.cachedRecords).insert(
          CachedRecordsCompanion.insert(
            cacheType: cacheType,
            cacheKey: cacheKey,
            payloadJson: payloadJson,
            updatedAt: updatedAt ?? DateTime.now(),
          ),
        );
      } else {
        await (update(
          _database.cachedRecords,
        )..where((record) => record.id.equals(existing.id))).write(
          CachedRecordsCompanion(
            payloadJson: Value(payloadJson),
            updatedAt: Value(updatedAt ?? DateTime.now()),
          ),
        );
      }

      return (select(_database.cachedRecords)..where(
            (record) =>
                record.cacheType.equals(cacheType) &
                record.cacheKey.equals(cacheKey),
          ))
          .getSingle();
    });
  }

  Future<bool> deleteCache(String cacheType, String cacheKey) async {
    final deleted =
        await (delete(_database.cachedRecords)..where(
              (record) =>
                  record.cacheType.equals(cacheType) &
                  record.cacheKey.equals(cacheKey),
            ))
            .go();
    return deleted > 0;
  }

  void _validateKey(String value, String argumentName) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        argumentName,
        'Key cache tidak boleh kosong.',
      );
    }
  }
}
