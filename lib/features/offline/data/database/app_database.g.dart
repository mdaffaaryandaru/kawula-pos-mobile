// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedRecordsTable extends CachedRecords
    with TableInfo<$CachedRecordsTable, CachedRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cacheTypeMeta = const VerificationMeta(
    'cacheType',
  );
  @override
  late final GeneratedColumn<String> cacheType = GeneratedColumn<String>(
    'cache_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cacheType,
    cacheKey,
    payloadJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cache_type')) {
      context.handle(
        _cacheTypeMeta,
        cacheType.isAcceptableOrUnknown(data['cache_type']!, _cacheTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheTypeMeta);
    }
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cacheType, cacheKey},
  ];
  @override
  CachedRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cacheType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_type'],
      )!,
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedRecordsTable createAlias(String alias) {
    return $CachedRecordsTable(attachedDatabase, alias);
  }
}

class CachedRecord extends DataClass implements Insertable<CachedRecord> {
  final int id;
  final String cacheType;
  final String cacheKey;
  final String payloadJson;
  final DateTime updatedAt;
  const CachedRecord({
    required this.id,
    required this.cacheType,
    required this.cacheKey,
    required this.payloadJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cache_type'] = Variable<String>(cacheType);
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedRecordsCompanion toCompanion(bool nullToAbsent) {
    return CachedRecordsCompanion(
      id: Value(id),
      cacheType: Value(cacheType),
      cacheKey: Value(cacheKey),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedRecord(
      id: serializer.fromJson<int>(json['id']),
      cacheType: serializer.fromJson<String>(json['cacheType']),
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cacheType': serializer.toJson<String>(cacheType),
      'cacheKey': serializer.toJson<String>(cacheKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedRecord copyWith({
    int? id,
    String? cacheType,
    String? cacheKey,
    String? payloadJson,
    DateTime? updatedAt,
  }) => CachedRecord(
    id: id ?? this.id,
    cacheType: cacheType ?? this.cacheType,
    cacheKey: cacheKey ?? this.cacheKey,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedRecord copyWithCompanion(CachedRecordsCompanion data) {
    return CachedRecord(
      id: data.id.present ? data.id.value : this.id,
      cacheType: data.cacheType.present ? data.cacheType.value : this.cacheType,
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedRecord(')
          ..write('id: $id, ')
          ..write('cacheType: $cacheType, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cacheType, cacheKey, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedRecord &&
          other.id == this.id &&
          other.cacheType == this.cacheType &&
          other.cacheKey == this.cacheKey &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class CachedRecordsCompanion extends UpdateCompanion<CachedRecord> {
  final Value<int> id;
  final Value<String> cacheType;
  final Value<String> cacheKey;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  const CachedRecordsCompanion({
    this.id = const Value.absent(),
    this.cacheType = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CachedRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String cacheType,
    required String cacheKey,
    required String payloadJson,
    required DateTime updatedAt,
  }) : cacheType = Value(cacheType),
       cacheKey = Value(cacheKey),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<CachedRecord> custom({
    Expression<int>? id,
    Expression<String>? cacheType,
    Expression<String>? cacheKey,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cacheType != null) 'cache_type': cacheType,
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CachedRecordsCompanion copyWith({
    Value<int>? id,
    Value<String>? cacheType,
    Value<String>? cacheKey,
    Value<String>? payloadJson,
    Value<DateTime>? updatedAt,
  }) {
    return CachedRecordsCompanion(
      id: id ?? this.id,
      cacheType: cacheType ?? this.cacheType,
      cacheKey: cacheKey ?? this.cacheKey,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cacheType.present) {
      map['cache_type'] = Variable<String>(cacheType.value);
    }
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedRecordsCompanion(')
          ..write('id: $id, ')
          ..write('cacheType: $cacheType, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $OfflineTransactionsTable extends OfflineTransactions
    with TableInfo<$OfflineTransactionsTable, OfflineTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outletIdMeta = const VerificationMeta(
    'outletId',
  );
  @override
  late final GeneratedColumn<String> outletId = GeneratedColumn<String>(
    'outlet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftIdMeta = const VerificationMeta(
    'shiftId',
  );
  @override
  late final GeneratedColumn<String> shiftId = GeneratedColumn<String>(
    'shift_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncMarkerMeta = const VerificationMeta(
    'syncMarker',
  );
  @override
  late final GeneratedColumn<String> syncMarker = GeneratedColumn<String>(
    'sync_marker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptSnapshotJsonMeta =
      const VerificationMeta('receiptSnapshotJson');
  @override
  late final GeneratedColumn<String> receiptSnapshotJson =
      GeneratedColumn<String>(
        'receipt_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_sync'),
  );
  static const VerificationMeta _remoteTransactionIdMeta =
      const VerificationMeta('remoteTransactionId');
  @override
  late final GeneratedColumn<String> remoteTransactionId =
      GeneratedColumn<String>(
        'remote_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtLocalMeta = const VerificationMeta(
    'createdAtLocal',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtLocal =
      GeneratedColumn<DateTime>(
        'created_at_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    ownerUserId,
    outletId,
    shiftId,
    transactionType,
    syncMarker,
    payloadJson,
    receiptSnapshotJson,
    status,
    remoteTransactionId,
    createdAtLocal,
    updatedAt,
    syncedAt,
    attemptCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUserIdMeta);
    }
    if (data.containsKey('outlet_id')) {
      context.handle(
        _outletIdMeta,
        outletId.isAcceptableOrUnknown(data['outlet_id']!, _outletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outletIdMeta);
    }
    if (data.containsKey('shift_id')) {
      context.handle(
        _shiftIdMeta,
        shiftId.isAcceptableOrUnknown(data['shift_id']!, _shiftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftIdMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('sync_marker')) {
      context.handle(
        _syncMarkerMeta,
        syncMarker.isAcceptableOrUnknown(data['sync_marker']!, _syncMarkerMeta),
      );
    } else if (isInserting) {
      context.missing(_syncMarkerMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('receipt_snapshot_json')) {
      context.handle(
        _receiptSnapshotJsonMeta,
        receiptSnapshotJson.isAcceptableOrUnknown(
          data['receipt_snapshot_json']!,
          _receiptSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptSnapshotJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('remote_transaction_id')) {
      context.handle(
        _remoteTransactionIdMeta,
        remoteTransactionId.isAcceptableOrUnknown(
          data['remote_transaction_id']!,
          _remoteTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at_local')) {
      context.handle(
        _createdAtLocalMeta,
        createdAtLocal.isAcceptableOrUnknown(
          data['created_at_local']!,
          _createdAtLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtLocalMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  OfflineTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineTransaction(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      )!,
      outletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outlet_id'],
      )!,
      shiftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_id'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      syncMarker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_marker'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      receiptSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_snapshot_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      remoteTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_transaction_id'],
      ),
      createdAtLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_local'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OfflineTransactionsTable createAlias(String alias) {
    return $OfflineTransactionsTable(attachedDatabase, alias);
  }
}

class OfflineTransaction extends DataClass
    implements Insertable<OfflineTransaction> {
  final String localId;
  final String ownerUserId;
  final String outletId;
  final String shiftId;
  final String transactionType;
  final String syncMarker;
  final String payloadJson;
  final String receiptSnapshotJson;
  final String status;
  final String? remoteTransactionId;
  final DateTime createdAtLocal;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final int attemptCount;
  final String? lastError;
  const OfflineTransaction({
    required this.localId,
    required this.ownerUserId,
    required this.outletId,
    required this.shiftId,
    required this.transactionType,
    required this.syncMarker,
    required this.payloadJson,
    required this.receiptSnapshotJson,
    required this.status,
    this.remoteTransactionId,
    required this.createdAtLocal,
    required this.updatedAt,
    this.syncedAt,
    required this.attemptCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['owner_user_id'] = Variable<String>(ownerUserId);
    map['outlet_id'] = Variable<String>(outletId);
    map['shift_id'] = Variable<String>(shiftId);
    map['transaction_type'] = Variable<String>(transactionType);
    map['sync_marker'] = Variable<String>(syncMarker);
    map['payload_json'] = Variable<String>(payloadJson);
    map['receipt_snapshot_json'] = Variable<String>(receiptSnapshotJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || remoteTransactionId != null) {
      map['remote_transaction_id'] = Variable<String>(remoteTransactionId);
    }
    map['created_at_local'] = Variable<DateTime>(createdAtLocal);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OfflineTransactionsCompanion toCompanion(bool nullToAbsent) {
    return OfflineTransactionsCompanion(
      localId: Value(localId),
      ownerUserId: Value(ownerUserId),
      outletId: Value(outletId),
      shiftId: Value(shiftId),
      transactionType: Value(transactionType),
      syncMarker: Value(syncMarker),
      payloadJson: Value(payloadJson),
      receiptSnapshotJson: Value(receiptSnapshotJson),
      status: Value(status),
      remoteTransactionId: remoteTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteTransactionId),
      createdAtLocal: Value(createdAtLocal),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OfflineTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineTransaction(
      localId: serializer.fromJson<String>(json['localId']),
      ownerUserId: serializer.fromJson<String>(json['ownerUserId']),
      outletId: serializer.fromJson<String>(json['outletId']),
      shiftId: serializer.fromJson<String>(json['shiftId']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      syncMarker: serializer.fromJson<String>(json['syncMarker']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      receiptSnapshotJson: serializer.fromJson<String>(
        json['receiptSnapshotJson'],
      ),
      status: serializer.fromJson<String>(json['status']),
      remoteTransactionId: serializer.fromJson<String?>(
        json['remoteTransactionId'],
      ),
      createdAtLocal: serializer.fromJson<DateTime>(json['createdAtLocal']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'ownerUserId': serializer.toJson<String>(ownerUserId),
      'outletId': serializer.toJson<String>(outletId),
      'shiftId': serializer.toJson<String>(shiftId),
      'transactionType': serializer.toJson<String>(transactionType),
      'syncMarker': serializer.toJson<String>(syncMarker),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'receiptSnapshotJson': serializer.toJson<String>(receiptSnapshotJson),
      'status': serializer.toJson<String>(status),
      'remoteTransactionId': serializer.toJson<String?>(remoteTransactionId),
      'createdAtLocal': serializer.toJson<DateTime>(createdAtLocal),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OfflineTransaction copyWith({
    String? localId,
    String? ownerUserId,
    String? outletId,
    String? shiftId,
    String? transactionType,
    String? syncMarker,
    String? payloadJson,
    String? receiptSnapshotJson,
    String? status,
    Value<String?> remoteTransactionId = const Value.absent(),
    DateTime? createdAtLocal,
    DateTime? updatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
  }) => OfflineTransaction(
    localId: localId ?? this.localId,
    ownerUserId: ownerUserId ?? this.ownerUserId,
    outletId: outletId ?? this.outletId,
    shiftId: shiftId ?? this.shiftId,
    transactionType: transactionType ?? this.transactionType,
    syncMarker: syncMarker ?? this.syncMarker,
    payloadJson: payloadJson ?? this.payloadJson,
    receiptSnapshotJson: receiptSnapshotJson ?? this.receiptSnapshotJson,
    status: status ?? this.status,
    remoteTransactionId: remoteTransactionId.present
        ? remoteTransactionId.value
        : this.remoteTransactionId,
    createdAtLocal: createdAtLocal ?? this.createdAtLocal,
    updatedAt: updatedAt ?? this.updatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OfflineTransaction copyWithCompanion(OfflineTransactionsCompanion data) {
    return OfflineTransaction(
      localId: data.localId.present ? data.localId.value : this.localId,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      outletId: data.outletId.present ? data.outletId.value : this.outletId,
      shiftId: data.shiftId.present ? data.shiftId.value : this.shiftId,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      syncMarker: data.syncMarker.present
          ? data.syncMarker.value
          : this.syncMarker,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      receiptSnapshotJson: data.receiptSnapshotJson.present
          ? data.receiptSnapshotJson.value
          : this.receiptSnapshotJson,
      status: data.status.present ? data.status.value : this.status,
      remoteTransactionId: data.remoteTransactionId.present
          ? data.remoteTransactionId.value
          : this.remoteTransactionId,
      createdAtLocal: data.createdAtLocal.present
          ? data.createdAtLocal.value
          : this.createdAtLocal,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineTransaction(')
          ..write('localId: $localId, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('outletId: $outletId, ')
          ..write('shiftId: $shiftId, ')
          ..write('transactionType: $transactionType, ')
          ..write('syncMarker: $syncMarker, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('receiptSnapshotJson: $receiptSnapshotJson, ')
          ..write('status: $status, ')
          ..write('remoteTransactionId: $remoteTransactionId, ')
          ..write('createdAtLocal: $createdAtLocal, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    ownerUserId,
    outletId,
    shiftId,
    transactionType,
    syncMarker,
    payloadJson,
    receiptSnapshotJson,
    status,
    remoteTransactionId,
    createdAtLocal,
    updatedAt,
    syncedAt,
    attemptCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineTransaction &&
          other.localId == this.localId &&
          other.ownerUserId == this.ownerUserId &&
          other.outletId == this.outletId &&
          other.shiftId == this.shiftId &&
          other.transactionType == this.transactionType &&
          other.syncMarker == this.syncMarker &&
          other.payloadJson == this.payloadJson &&
          other.receiptSnapshotJson == this.receiptSnapshotJson &&
          other.status == this.status &&
          other.remoteTransactionId == this.remoteTransactionId &&
          other.createdAtLocal == this.createdAtLocal &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError);
}

class OfflineTransactionsCompanion extends UpdateCompanion<OfflineTransaction> {
  final Value<String> localId;
  final Value<String> ownerUserId;
  final Value<String> outletId;
  final Value<String> shiftId;
  final Value<String> transactionType;
  final Value<String> syncMarker;
  final Value<String> payloadJson;
  final Value<String> receiptSnapshotJson;
  final Value<String> status;
  final Value<String?> remoteTransactionId;
  final Value<DateTime> createdAtLocal;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<int> rowid;
  const OfflineTransactionsCompanion({
    this.localId = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.outletId = const Value.absent(),
    this.shiftId = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.syncMarker = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.receiptSnapshotJson = const Value.absent(),
    this.status = const Value.absent(),
    this.remoteTransactionId = const Value.absent(),
    this.createdAtLocal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineTransactionsCompanion.insert({
    required String localId,
    required String ownerUserId,
    required String outletId,
    required String shiftId,
    required String transactionType,
    required String syncMarker,
    required String payloadJson,
    required String receiptSnapshotJson,
    this.status = const Value.absent(),
    this.remoteTransactionId = const Value.absent(),
    required DateTime createdAtLocal,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       ownerUserId = Value(ownerUserId),
       outletId = Value(outletId),
       shiftId = Value(shiftId),
       transactionType = Value(transactionType),
       syncMarker = Value(syncMarker),
       payloadJson = Value(payloadJson),
       receiptSnapshotJson = Value(receiptSnapshotJson),
       createdAtLocal = Value(createdAtLocal),
       updatedAt = Value(updatedAt);
  static Insertable<OfflineTransaction> custom({
    Expression<String>? localId,
    Expression<String>? ownerUserId,
    Expression<String>? outletId,
    Expression<String>? shiftId,
    Expression<String>? transactionType,
    Expression<String>? syncMarker,
    Expression<String>? payloadJson,
    Expression<String>? receiptSnapshotJson,
    Expression<String>? status,
    Expression<String>? remoteTransactionId,
    Expression<DateTime>? createdAtLocal,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (outletId != null) 'outlet_id': outletId,
      if (shiftId != null) 'shift_id': shiftId,
      if (transactionType != null) 'transaction_type': transactionType,
      if (syncMarker != null) 'sync_marker': syncMarker,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (receiptSnapshotJson != null)
        'receipt_snapshot_json': receiptSnapshotJson,
      if (status != null) 'status': status,
      if (remoteTransactionId != null)
        'remote_transaction_id': remoteTransactionId,
      if (createdAtLocal != null) 'created_at_local': createdAtLocal,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineTransactionsCompanion copyWith({
    Value<String>? localId,
    Value<String>? ownerUserId,
    Value<String>? outletId,
    Value<String>? shiftId,
    Value<String>? transactionType,
    Value<String>? syncMarker,
    Value<String>? payloadJson,
    Value<String>? receiptSnapshotJson,
    Value<String>? status,
    Value<String?>? remoteTransactionId,
    Value<DateTime>? createdAtLocal,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return OfflineTransactionsCompanion(
      localId: localId ?? this.localId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      outletId: outletId ?? this.outletId,
      shiftId: shiftId ?? this.shiftId,
      transactionType: transactionType ?? this.transactionType,
      syncMarker: syncMarker ?? this.syncMarker,
      payloadJson: payloadJson ?? this.payloadJson,
      receiptSnapshotJson: receiptSnapshotJson ?? this.receiptSnapshotJson,
      status: status ?? this.status,
      remoteTransactionId: remoteTransactionId ?? this.remoteTransactionId,
      createdAtLocal: createdAtLocal ?? this.createdAtLocal,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (outletId.present) {
      map['outlet_id'] = Variable<String>(outletId.value);
    }
    if (shiftId.present) {
      map['shift_id'] = Variable<String>(shiftId.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (syncMarker.present) {
      map['sync_marker'] = Variable<String>(syncMarker.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (receiptSnapshotJson.present) {
      map['receipt_snapshot_json'] = Variable<String>(
        receiptSnapshotJson.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (remoteTransactionId.present) {
      map['remote_transaction_id'] = Variable<String>(
        remoteTransactionId.value,
      );
    }
    if (createdAtLocal.present) {
      map['created_at_local'] = Variable<DateTime>(createdAtLocal.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineTransactionsCompanion(')
          ..write('localId: $localId, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('outletId: $outletId, ')
          ..write('shiftId: $shiftId, ')
          ..write('transactionType: $transactionType, ')
          ..write('syncMarker: $syncMarker, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('receiptSnapshotJson: $receiptSnapshotJson, ')
          ..write('status: $status, ')
          ..write('remoteTransactionId: $remoteTransactionId, ')
          ..write('createdAtLocal: $createdAtLocal, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineTransactionResolutionsTable extends OfflineTransactionResolutions
    with
        TableInfo<
          $OfflineTransactionResolutionsTable,
          OfflineTransactionResolution
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineTransactionResolutionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outletIdMeta = const VerificationMeta(
    'outletId',
  );
  @override
  late final GeneratedColumn<String> outletId = GeneratedColumn<String>(
    'outlet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _previousStatusMeta = const VerificationMeta(
    'previousStatus',
  );
  @override
  late final GeneratedColumn<String> previousStatus = GeneratedColumn<String>(
    'previous_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultingStatusMeta = const VerificationMeta(
    'resultingStatus',
  );
  @override
  late final GeneratedColumn<String> resultingStatus = GeneratedColumn<String>(
    'resulting_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolutionTypeMeta = const VerificationMeta(
    'resolutionType',
  );
  @override
  late final GeneratedColumn<String> resolutionType = GeneratedColumn<String>(
    'resolution_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteTransactionIdMeta =
      const VerificationMeta('remoteTransactionId');
  @override
  late final GeneratedColumn<String> remoteTransactionId =
      GeneratedColumn<String>(
        'remote_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolvingAdminUserIdMeta =
      const VerificationMeta('resolvingAdminUserId');
  @override
  late final GeneratedColumn<String> resolvingAdminUserId =
      GeneratedColumn<String>(
        'resolving_admin_user_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _resolvingAdminRoleMeta =
      const VerificationMeta('resolvingAdminRole');
  @override
  late final GeneratedColumn<String> resolvingAdminRole =
      GeneratedColumn<String>(
        'resolving_admin_role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    outletId,
    previousStatus,
    resultingStatus,
    resolutionType,
    remoteTransactionId,
    resolvingAdminUserId,
    resolvingAdminRole,
    resolvedAt,
    reason,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_transaction_resolutions';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineTransactionResolution> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('outlet_id')) {
      context.handle(
        _outletIdMeta,
        outletId.isAcceptableOrUnknown(data['outlet_id']!, _outletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outletIdMeta);
    }
    if (data.containsKey('previous_status')) {
      context.handle(
        _previousStatusMeta,
        previousStatus.isAcceptableOrUnknown(
          data['previous_status']!,
          _previousStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_previousStatusMeta);
    }
    if (data.containsKey('resulting_status')) {
      context.handle(
        _resultingStatusMeta,
        resultingStatus.isAcceptableOrUnknown(
          data['resulting_status']!,
          _resultingStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resultingStatusMeta);
    }
    if (data.containsKey('resolution_type')) {
      context.handle(
        _resolutionTypeMeta,
        resolutionType.isAcceptableOrUnknown(
          data['resolution_type']!,
          _resolutionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolutionTypeMeta);
    }
    if (data.containsKey('remote_transaction_id')) {
      context.handle(
        _remoteTransactionIdMeta,
        remoteTransactionId.isAcceptableOrUnknown(
          data['remote_transaction_id']!,
          _remoteTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('resolving_admin_user_id')) {
      context.handle(
        _resolvingAdminUserIdMeta,
        resolvingAdminUserId.isAcceptableOrUnknown(
          data['resolving_admin_user_id']!,
          _resolvingAdminUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolvingAdminUserIdMeta);
    }
    if (data.containsKey('resolving_admin_role')) {
      context.handle(
        _resolvingAdminRoleMeta,
        resolvingAdminRole.isAcceptableOrUnknown(
          data['resolving_admin_role']!,
          _resolvingAdminRoleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolvingAdminRoleMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_resolvedAtMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineTransactionResolution map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineTransactionResolution(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      outletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outlet_id'],
      )!,
      previousStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_status'],
      )!,
      resultingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resulting_status'],
      )!,
      resolutionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_type'],
      )!,
      remoteTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_transaction_id'],
      ),
      resolvingAdminUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolving_admin_user_id'],
      )!,
      resolvingAdminRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolving_admin_role'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $OfflineTransactionResolutionsTable createAlias(String alias) {
    return $OfflineTransactionResolutionsTable(attachedDatabase, alias);
  }
}

class OfflineTransactionResolution extends DataClass
    implements Insertable<OfflineTransactionResolution> {
  final int id;
  final String localId;
  final String outletId;
  final String previousStatus;
  final String resultingStatus;
  final String resolutionType;
  final String? remoteTransactionId;
  final String resolvingAdminUserId;
  final String resolvingAdminRole;
  final DateTime resolvedAt;
  final String reason;
  final String? notes;
  const OfflineTransactionResolution({
    required this.id,
    required this.localId,
    required this.outletId,
    required this.previousStatus,
    required this.resultingStatus,
    required this.resolutionType,
    this.remoteTransactionId,
    required this.resolvingAdminUserId,
    required this.resolvingAdminRole,
    required this.resolvedAt,
    required this.reason,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_id'] = Variable<String>(localId);
    map['outlet_id'] = Variable<String>(outletId);
    map['previous_status'] = Variable<String>(previousStatus);
    map['resulting_status'] = Variable<String>(resultingStatus);
    map['resolution_type'] = Variable<String>(resolutionType);
    if (!nullToAbsent || remoteTransactionId != null) {
      map['remote_transaction_id'] = Variable<String>(remoteTransactionId);
    }
    map['resolving_admin_user_id'] = Variable<String>(resolvingAdminUserId);
    map['resolving_admin_role'] = Variable<String>(resolvingAdminRole);
    map['resolved_at'] = Variable<DateTime>(resolvedAt);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  OfflineTransactionResolutionsCompanion toCompanion(bool nullToAbsent) {
    return OfflineTransactionResolutionsCompanion(
      id: Value(id),
      localId: Value(localId),
      outletId: Value(outletId),
      previousStatus: Value(previousStatus),
      resultingStatus: Value(resultingStatus),
      resolutionType: Value(resolutionType),
      remoteTransactionId: remoteTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteTransactionId),
      resolvingAdminUserId: Value(resolvingAdminUserId),
      resolvingAdminRole: Value(resolvingAdminRole),
      resolvedAt: Value(resolvedAt),
      reason: Value(reason),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory OfflineTransactionResolution.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineTransactionResolution(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      outletId: serializer.fromJson<String>(json['outletId']),
      previousStatus: serializer.fromJson<String>(json['previousStatus']),
      resultingStatus: serializer.fromJson<String>(json['resultingStatus']),
      resolutionType: serializer.fromJson<String>(json['resolutionType']),
      remoteTransactionId: serializer.fromJson<String?>(
        json['remoteTransactionId'],
      ),
      resolvingAdminUserId: serializer.fromJson<String>(
        json['resolvingAdminUserId'],
      ),
      resolvingAdminRole: serializer.fromJson<String>(
        json['resolvingAdminRole'],
      ),
      resolvedAt: serializer.fromJson<DateTime>(json['resolvedAt']),
      reason: serializer.fromJson<String>(json['reason']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String>(localId),
      'outletId': serializer.toJson<String>(outletId),
      'previousStatus': serializer.toJson<String>(previousStatus),
      'resultingStatus': serializer.toJson<String>(resultingStatus),
      'resolutionType': serializer.toJson<String>(resolutionType),
      'remoteTransactionId': serializer.toJson<String?>(remoteTransactionId),
      'resolvingAdminUserId': serializer.toJson<String>(resolvingAdminUserId),
      'resolvingAdminRole': serializer.toJson<String>(resolvingAdminRole),
      'resolvedAt': serializer.toJson<DateTime>(resolvedAt),
      'reason': serializer.toJson<String>(reason),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  OfflineTransactionResolution copyWith({
    int? id,
    String? localId,
    String? outletId,
    String? previousStatus,
    String? resultingStatus,
    String? resolutionType,
    Value<String?> remoteTransactionId = const Value.absent(),
    String? resolvingAdminUserId,
    String? resolvingAdminRole,
    DateTime? resolvedAt,
    String? reason,
    Value<String?> notes = const Value.absent(),
  }) => OfflineTransactionResolution(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    outletId: outletId ?? this.outletId,
    previousStatus: previousStatus ?? this.previousStatus,
    resultingStatus: resultingStatus ?? this.resultingStatus,
    resolutionType: resolutionType ?? this.resolutionType,
    remoteTransactionId: remoteTransactionId.present
        ? remoteTransactionId.value
        : this.remoteTransactionId,
    resolvingAdminUserId: resolvingAdminUserId ?? this.resolvingAdminUserId,
    resolvingAdminRole: resolvingAdminRole ?? this.resolvingAdminRole,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    reason: reason ?? this.reason,
    notes: notes.present ? notes.value : this.notes,
  );
  OfflineTransactionResolution copyWithCompanion(
    OfflineTransactionResolutionsCompanion data,
  ) {
    return OfflineTransactionResolution(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      outletId: data.outletId.present ? data.outletId.value : this.outletId,
      previousStatus: data.previousStatus.present
          ? data.previousStatus.value
          : this.previousStatus,
      resultingStatus: data.resultingStatus.present
          ? data.resultingStatus.value
          : this.resultingStatus,
      resolutionType: data.resolutionType.present
          ? data.resolutionType.value
          : this.resolutionType,
      remoteTransactionId: data.remoteTransactionId.present
          ? data.remoteTransactionId.value
          : this.remoteTransactionId,
      resolvingAdminUserId: data.resolvingAdminUserId.present
          ? data.resolvingAdminUserId.value
          : this.resolvingAdminUserId,
      resolvingAdminRole: data.resolvingAdminRole.present
          ? data.resolvingAdminRole.value
          : this.resolvingAdminRole,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      reason: data.reason.present ? data.reason.value : this.reason,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineTransactionResolution(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('outletId: $outletId, ')
          ..write('previousStatus: $previousStatus, ')
          ..write('resultingStatus: $resultingStatus, ')
          ..write('resolutionType: $resolutionType, ')
          ..write('remoteTransactionId: $remoteTransactionId, ')
          ..write('resolvingAdminUserId: $resolvingAdminUserId, ')
          ..write('resolvingAdminRole: $resolvingAdminRole, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localId,
    outletId,
    previousStatus,
    resultingStatus,
    resolutionType,
    remoteTransactionId,
    resolvingAdminUserId,
    resolvingAdminRole,
    resolvedAt,
    reason,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineTransactionResolution &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.outletId == this.outletId &&
          other.previousStatus == this.previousStatus &&
          other.resultingStatus == this.resultingStatus &&
          other.resolutionType == this.resolutionType &&
          other.remoteTransactionId == this.remoteTransactionId &&
          other.resolvingAdminUserId == this.resolvingAdminUserId &&
          other.resolvingAdminRole == this.resolvingAdminRole &&
          other.resolvedAt == this.resolvedAt &&
          other.reason == this.reason &&
          other.notes == this.notes);
}

class OfflineTransactionResolutionsCompanion
    extends UpdateCompanion<OfflineTransactionResolution> {
  final Value<int> id;
  final Value<String> localId;
  final Value<String> outletId;
  final Value<String> previousStatus;
  final Value<String> resultingStatus;
  final Value<String> resolutionType;
  final Value<String?> remoteTransactionId;
  final Value<String> resolvingAdminUserId;
  final Value<String> resolvingAdminRole;
  final Value<DateTime> resolvedAt;
  final Value<String> reason;
  final Value<String?> notes;
  const OfflineTransactionResolutionsCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.outletId = const Value.absent(),
    this.previousStatus = const Value.absent(),
    this.resultingStatus = const Value.absent(),
    this.resolutionType = const Value.absent(),
    this.remoteTransactionId = const Value.absent(),
    this.resolvingAdminUserId = const Value.absent(),
    this.resolvingAdminRole = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.reason = const Value.absent(),
    this.notes = const Value.absent(),
  });
  OfflineTransactionResolutionsCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    required String outletId,
    required String previousStatus,
    required String resultingStatus,
    required String resolutionType,
    this.remoteTransactionId = const Value.absent(),
    required String resolvingAdminUserId,
    required String resolvingAdminRole,
    required DateTime resolvedAt,
    required String reason,
    this.notes = const Value.absent(),
  }) : localId = Value(localId),
       outletId = Value(outletId),
       previousStatus = Value(previousStatus),
       resultingStatus = Value(resultingStatus),
       resolutionType = Value(resolutionType),
       resolvingAdminUserId = Value(resolvingAdminUserId),
       resolvingAdminRole = Value(resolvingAdminRole),
       resolvedAt = Value(resolvedAt),
       reason = Value(reason);
  static Insertable<OfflineTransactionResolution> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? outletId,
    Expression<String>? previousStatus,
    Expression<String>? resultingStatus,
    Expression<String>? resolutionType,
    Expression<String>? remoteTransactionId,
    Expression<String>? resolvingAdminUserId,
    Expression<String>? resolvingAdminRole,
    Expression<DateTime>? resolvedAt,
    Expression<String>? reason,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (outletId != null) 'outlet_id': outletId,
      if (previousStatus != null) 'previous_status': previousStatus,
      if (resultingStatus != null) 'resulting_status': resultingStatus,
      if (resolutionType != null) 'resolution_type': resolutionType,
      if (remoteTransactionId != null)
        'remote_transaction_id': remoteTransactionId,
      if (resolvingAdminUserId != null)
        'resolving_admin_user_id': resolvingAdminUserId,
      if (resolvingAdminRole != null)
        'resolving_admin_role': resolvingAdminRole,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
    });
  }

  OfflineTransactionResolutionsCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<String>? outletId,
    Value<String>? previousStatus,
    Value<String>? resultingStatus,
    Value<String>? resolutionType,
    Value<String?>? remoteTransactionId,
    Value<String>? resolvingAdminUserId,
    Value<String>? resolvingAdminRole,
    Value<DateTime>? resolvedAt,
    Value<String>? reason,
    Value<String?>? notes,
  }) {
    return OfflineTransactionResolutionsCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      outletId: outletId ?? this.outletId,
      previousStatus: previousStatus ?? this.previousStatus,
      resultingStatus: resultingStatus ?? this.resultingStatus,
      resolutionType: resolutionType ?? this.resolutionType,
      remoteTransactionId: remoteTransactionId ?? this.remoteTransactionId,
      resolvingAdminUserId: resolvingAdminUserId ?? this.resolvingAdminUserId,
      resolvingAdminRole: resolvingAdminRole ?? this.resolvingAdminRole,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (outletId.present) {
      map['outlet_id'] = Variable<String>(outletId.value);
    }
    if (previousStatus.present) {
      map['previous_status'] = Variable<String>(previousStatus.value);
    }
    if (resultingStatus.present) {
      map['resulting_status'] = Variable<String>(resultingStatus.value);
    }
    if (resolutionType.present) {
      map['resolution_type'] = Variable<String>(resolutionType.value);
    }
    if (remoteTransactionId.present) {
      map['remote_transaction_id'] = Variable<String>(
        remoteTransactionId.value,
      );
    }
    if (resolvingAdminUserId.present) {
      map['resolving_admin_user_id'] = Variable<String>(
        resolvingAdminUserId.value,
      );
    }
    if (resolvingAdminRole.present) {
      map['resolving_admin_role'] = Variable<String>(resolvingAdminRole.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineTransactionResolutionsCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('outletId: $outletId, ')
          ..write('previousStatus: $previousStatus, ')
          ..write('resultingStatus: $resultingStatus, ')
          ..write('resolutionType: $resolutionType, ')
          ..write('remoteTransactionId: $remoteTransactionId, ')
          ..write('resolvingAdminUserId: $resolvingAdminUserId, ')
          ..write('resolvingAdminRole: $resolvingAdminRole, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedRecordsTable cachedRecords = $CachedRecordsTable(this);
  late final $OfflineTransactionsTable offlineTransactions =
      $OfflineTransactionsTable(this);
  late final $OfflineTransactionResolutionsTable offlineTransactionResolutions =
      $OfflineTransactionResolutionsTable(this);
  late final Index offlineTransactionsOwnerStatusCreatedIdx = Index(
    'offline_transactions_owner_status_created_idx',
    'CREATE INDEX offline_transactions_owner_status_created_idx ON offline_transactions (owner_user_id, status, created_at_local)',
  );
  late final Index offlineTransactionsOutletIdx = Index(
    'offline_transactions_outlet_idx',
    'CREATE INDEX offline_transactions_outlet_idx ON offline_transactions (outlet_id)',
  );
  late final Index offlineTransactionsShiftIdx = Index(
    'offline_transactions_shift_idx',
    'CREATE INDEX offline_transactions_shift_idx ON offline_transactions (shift_id)',
  );
  late final Index offlineTransactionsStatusIdx = Index(
    'offline_transactions_status_idx',
    'CREATE INDEX offline_transactions_status_idx ON offline_transactions (status)',
  );
  late final Index offlineTransactionsCreatedIdx = Index(
    'offline_transactions_created_idx',
    'CREATE INDEX offline_transactions_created_idx ON offline_transactions (created_at_local)',
  );
  late final Index offlineTransactionResolutionsLocalCreatedIdx = Index(
    'offline_transaction_resolutions_local_created_idx',
    'CREATE INDEX offline_transaction_resolutions_local_created_idx ON offline_transaction_resolutions (local_id, resolved_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedRecords,
    offlineTransactions,
    offlineTransactionResolutions,
    offlineTransactionsOwnerStatusCreatedIdx,
    offlineTransactionsOutletIdx,
    offlineTransactionsShiftIdx,
    offlineTransactionsStatusIdx,
    offlineTransactionsCreatedIdx,
    offlineTransactionResolutionsLocalCreatedIdx,
  ];
}

typedef $$CachedRecordsTableCreateCompanionBuilder =
    CachedRecordsCompanion Function({
      Value<int> id,
      required String cacheType,
      required String cacheKey,
      required String payloadJson,
      required DateTime updatedAt,
    });
typedef $$CachedRecordsTableUpdateCompanionBuilder =
    CachedRecordsCompanion Function({
      Value<int> id,
      Value<String> cacheType,
      Value<String> cacheKey,
      Value<String> payloadJson,
      Value<DateTime> updatedAt,
    });

class $$CachedRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedRecordsTable> {
  $$CachedRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheType => $composableBuilder(
    column: $table.cacheType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedRecordsTable> {
  $$CachedRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheType => $composableBuilder(
    column: $table.cacheType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedRecordsTable> {
  $$CachedRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cacheType =>
      $composableBuilder(column: $table.cacheType, builder: (column) => column);

  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedRecordsTable,
          CachedRecord,
          $$CachedRecordsTableFilterComposer,
          $$CachedRecordsTableOrderingComposer,
          $$CachedRecordsTableAnnotationComposer,
          $$CachedRecordsTableCreateCompanionBuilder,
          $$CachedRecordsTableUpdateCompanionBuilder,
          (
            CachedRecord,
            BaseReferences<_$AppDatabase, $CachedRecordsTable, CachedRecord>,
          ),
          CachedRecord,
          PrefetchHooks Function()
        > {
  $$CachedRecordsTableTableManager(_$AppDatabase db, $CachedRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cacheType = const Value.absent(),
                Value<String> cacheKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CachedRecordsCompanion(
                id: id,
                cacheType: cacheType,
                cacheKey: cacheKey,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String cacheType,
                required String cacheKey,
                required String payloadJson,
                required DateTime updatedAt,
              }) => CachedRecordsCompanion.insert(
                id: id,
                cacheType: cacheType,
                cacheKey: cacheKey,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedRecordsTable, CachedRecord>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedRecordsTable,
                    CachedRecord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedRecordsTable,
      CachedRecord,
      $$CachedRecordsTableFilterComposer,
      $$CachedRecordsTableOrderingComposer,
      $$CachedRecordsTableAnnotationComposer,
      $$CachedRecordsTableCreateCompanionBuilder,
      $$CachedRecordsTableUpdateCompanionBuilder,
      (
        CachedRecord,
        BaseReferences<_$AppDatabase, $CachedRecordsTable, CachedRecord>,
      ),
      CachedRecord,
      PrefetchHooks Function()
    >;
typedef $$OfflineTransactionsTableCreateCompanionBuilder =
    OfflineTransactionsCompanion Function({
      required String localId,
      required String ownerUserId,
      required String outletId,
      required String shiftId,
      required String transactionType,
      required String syncMarker,
      required String payloadJson,
      required String receiptSnapshotJson,
      Value<String> status,
      Value<String?> remoteTransactionId,
      required DateTime createdAtLocal,
      required DateTime updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$OfflineTransactionsTableUpdateCompanionBuilder =
    OfflineTransactionsCompanion Function({
      Value<String> localId,
      Value<String> ownerUserId,
      Value<String> outletId,
      Value<String> shiftId,
      Value<String> transactionType,
      Value<String> syncMarker,
      Value<String> payloadJson,
      Value<String> receiptSnapshotJson,
      Value<String> status,
      Value<String?> remoteTransactionId,
      Value<DateTime> createdAtLocal,
      Value<DateTime> updatedAt,
      Value<DateTime?> syncedAt,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$OfflineTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineTransactionsTable> {
  $$OfflineTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncMarker => $composableBuilder(
    column: $table.syncMarker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptSnapshotJson => $composableBuilder(
    column: $table.receiptSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteTransactionId => $composableBuilder(
    column: $table.remoteTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineTransactionsTable> {
  $$OfflineTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftId => $composableBuilder(
    column: $table.shiftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncMarker => $composableBuilder(
    column: $table.syncMarker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptSnapshotJson => $composableBuilder(
    column: $table.receiptSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteTransactionId => $composableBuilder(
    column: $table.remoteTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineTransactionsTable> {
  $$OfflineTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outletId =>
      $composableBuilder(column: $table.outletId, builder: (column) => column);

  GeneratedColumn<String> get shiftId =>
      $composableBuilder(column: $table.shiftId, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncMarker => $composableBuilder(
    column: $table.syncMarker,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptSnapshotJson => $composableBuilder(
    column: $table.receiptSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get remoteTransactionId => $composableBuilder(
    column: $table.remoteTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtLocal => $composableBuilder(
    column: $table.createdAtLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OfflineTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineTransactionsTable,
          OfflineTransaction,
          $$OfflineTransactionsTableFilterComposer,
          $$OfflineTransactionsTableOrderingComposer,
          $$OfflineTransactionsTableAnnotationComposer,
          $$OfflineTransactionsTableCreateCompanionBuilder,
          $$OfflineTransactionsTableUpdateCompanionBuilder,
          (
            OfflineTransaction,
            BaseReferences<
              _$AppDatabase,
              $OfflineTransactionsTable,
              OfflineTransaction
            >,
          ),
          OfflineTransaction,
          PrefetchHooks Function()
        > {
  $$OfflineTransactionsTableTableManager(
    _$AppDatabase db,
    $OfflineTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfflineTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> ownerUserId = const Value.absent(),
                Value<String> outletId = const Value.absent(),
                Value<String> shiftId = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String> syncMarker = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> receiptSnapshotJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> remoteTransactionId = const Value.absent(),
                Value<DateTime> createdAtLocal = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineTransactionsCompanion(
                localId: localId,
                ownerUserId: ownerUserId,
                outletId: outletId,
                shiftId: shiftId,
                transactionType: transactionType,
                syncMarker: syncMarker,
                payloadJson: payloadJson,
                receiptSnapshotJson: receiptSnapshotJson,
                status: status,
                remoteTransactionId: remoteTransactionId,
                createdAtLocal: createdAtLocal,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                attemptCount: attemptCount,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required String ownerUserId,
                required String outletId,
                required String shiftId,
                required String transactionType,
                required String syncMarker,
                required String payloadJson,
                required String receiptSnapshotJson,
                Value<String> status = const Value.absent(),
                Value<String?> remoteTransactionId = const Value.absent(),
                required DateTime createdAtLocal,
                required DateTime updatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineTransactionsCompanion.insert(
                localId: localId,
                ownerUserId: ownerUserId,
                outletId: outletId,
                shiftId: shiftId,
                transactionType: transactionType,
                syncMarker: syncMarker,
                payloadJson: payloadJson,
                receiptSnapshotJson: receiptSnapshotJson,
                status: status,
                remoteTransactionId: remoteTransactionId,
                createdAtLocal: createdAtLocal,
                updatedAt: updatedAt,
                syncedAt: syncedAt,
                attemptCount: attemptCount,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineTransactionsTable, OfflineTransaction>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $OfflineTransactionsTable,
                    OfflineTransaction
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineTransactionsTable,
      OfflineTransaction,
      $$OfflineTransactionsTableFilterComposer,
      $$OfflineTransactionsTableOrderingComposer,
      $$OfflineTransactionsTableAnnotationComposer,
      $$OfflineTransactionsTableCreateCompanionBuilder,
      $$OfflineTransactionsTableUpdateCompanionBuilder,
      (
        OfflineTransaction,
        BaseReferences<
          _$AppDatabase,
          $OfflineTransactionsTable,
          OfflineTransaction
        >,
      ),
      OfflineTransaction,
      PrefetchHooks Function()
    >;
typedef $$OfflineTransactionResolutionsTableCreateCompanionBuilder =
    OfflineTransactionResolutionsCompanion Function({
      Value<int> id,
      required String localId,
      required String outletId,
      required String previousStatus,
      required String resultingStatus,
      required String resolutionType,
      Value<String?> remoteTransactionId,
      required String resolvingAdminUserId,
      required String resolvingAdminRole,
      required DateTime resolvedAt,
      required String reason,
      Value<String?> notes,
    });
typedef $$OfflineTransactionResolutionsTableUpdateCompanionBuilder =
    OfflineTransactionResolutionsCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<String> outletId,
      Value<String> previousStatus,
      Value<String> resultingStatus,
      Value<String> resolutionType,
      Value<String?> remoteTransactionId,
      Value<String> resolvingAdminUserId,
      Value<String> resolvingAdminRole,
      Value<DateTime> resolvedAt,
      Value<String> reason,
      Value<String?> notes,
    });

class $$OfflineTransactionResolutionsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineTransactionResolutionsTable> {
  $$OfflineTransactionResolutionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousStatus => $composableBuilder(
    column: $table.previousStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resultingStatus => $composableBuilder(
    column: $table.resultingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionType => $composableBuilder(
    column: $table.resolutionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteTransactionId => $composableBuilder(
    column: $table.remoteTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvingAdminUserId => $composableBuilder(
    column: $table.resolvingAdminUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvingAdminRole => $composableBuilder(
    column: $table.resolvingAdminRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineTransactionResolutionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineTransactionResolutionsTable> {
  $$OfflineTransactionResolutionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outletId => $composableBuilder(
    column: $table.outletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousStatus => $composableBuilder(
    column: $table.previousStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resultingStatus => $composableBuilder(
    column: $table.resultingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionType => $composableBuilder(
    column: $table.resolutionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteTransactionId => $composableBuilder(
    column: $table.remoteTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvingAdminUserId => $composableBuilder(
    column: $table.resolvingAdminUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvingAdminRole => $composableBuilder(
    column: $table.resolvingAdminRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineTransactionResolutionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineTransactionResolutionsTable> {
  $$OfflineTransactionResolutionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get outletId =>
      $composableBuilder(column: $table.outletId, builder: (column) => column);

  GeneratedColumn<String> get previousStatus => $composableBuilder(
    column: $table.previousStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resultingStatus => $composableBuilder(
    column: $table.resultingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionType => $composableBuilder(
    column: $table.resolutionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteTransactionId => $composableBuilder(
    column: $table.remoteTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolvingAdminUserId => $composableBuilder(
    column: $table.resolvingAdminUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolvingAdminRole => $composableBuilder(
    column: $table.resolvingAdminRole,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$OfflineTransactionResolutionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineTransactionResolutionsTable,
          OfflineTransactionResolution,
          $$OfflineTransactionResolutionsTableFilterComposer,
          $$OfflineTransactionResolutionsTableOrderingComposer,
          $$OfflineTransactionResolutionsTableAnnotationComposer,
          $$OfflineTransactionResolutionsTableCreateCompanionBuilder,
          $$OfflineTransactionResolutionsTableUpdateCompanionBuilder,
          (
            OfflineTransactionResolution,
            BaseReferences<
              _$AppDatabase,
              $OfflineTransactionResolutionsTable,
              OfflineTransactionResolution
            >,
          ),
          OfflineTransactionResolution,
          PrefetchHooks Function()
        > {
  $$OfflineTransactionResolutionsTableTableManager(
    _$AppDatabase db,
    $OfflineTransactionResolutionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineTransactionResolutionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OfflineTransactionResolutionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfflineTransactionResolutionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> outletId = const Value.absent(),
                Value<String> previousStatus = const Value.absent(),
                Value<String> resultingStatus = const Value.absent(),
                Value<String> resolutionType = const Value.absent(),
                Value<String?> remoteTransactionId = const Value.absent(),
                Value<String> resolvingAdminUserId = const Value.absent(),
                Value<String> resolvingAdminRole = const Value.absent(),
                Value<DateTime> resolvedAt = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => OfflineTransactionResolutionsCompanion(
                id: id,
                localId: localId,
                outletId: outletId,
                previousStatus: previousStatus,
                resultingStatus: resultingStatus,
                resolutionType: resolutionType,
                remoteTransactionId: remoteTransactionId,
                resolvingAdminUserId: resolvingAdminUserId,
                resolvingAdminRole: resolvingAdminRole,
                resolvedAt: resolvedAt,
                reason: reason,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localId,
                required String outletId,
                required String previousStatus,
                required String resultingStatus,
                required String resolutionType,
                Value<String?> remoteTransactionId = const Value.absent(),
                required String resolvingAdminUserId,
                required String resolvingAdminRole,
                required DateTime resolvedAt,
                required String reason,
                Value<String?> notes = const Value.absent(),
              }) => OfflineTransactionResolutionsCompanion.insert(
                id: id,
                localId: localId,
                outletId: outletId,
                previousStatus: previousStatus,
                resultingStatus: resultingStatus,
                resolutionType: resolutionType,
                remoteTransactionId: remoteTransactionId,
                resolvingAdminUserId: resolvingAdminUserId,
                resolvingAdminRole: resolvingAdminRole,
                resolvedAt: resolvedAt,
                reason: reason,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $OfflineTransactionResolutionsTable,
                    OfflineTransactionResolution
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OfflineTransactionResolutionsTable,
                    OfflineTransactionResolution
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineTransactionResolutionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineTransactionResolutionsTable,
      OfflineTransactionResolution,
      $$OfflineTransactionResolutionsTableFilterComposer,
      $$OfflineTransactionResolutionsTableOrderingComposer,
      $$OfflineTransactionResolutionsTableAnnotationComposer,
      $$OfflineTransactionResolutionsTableCreateCompanionBuilder,
      $$OfflineTransactionResolutionsTableUpdateCompanionBuilder,
      (
        OfflineTransactionResolution,
        BaseReferences<
          _$AppDatabase,
          $OfflineTransactionResolutionsTable,
          OfflineTransactionResolution
        >,
      ),
      OfflineTransactionResolution,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedRecordsTableTableManager get cachedRecords =>
      $$CachedRecordsTableTableManager(_db, _db.cachedRecords);
  $$OfflineTransactionsTableTableManager get offlineTransactions =>
      $$OfflineTransactionsTableTableManager(_db, _db.offlineTransactions);
  $$OfflineTransactionResolutionsTableTableManager
  get offlineTransactionResolutions =>
      $$OfflineTransactionResolutionsTableTableManager(
        _db,
        _db.offlineTransactionResolutions,
      );
}
