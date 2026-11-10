import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kawula_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kawula_pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kawula_pos/features/shifts/data/models/active_shift_model.dart';
import 'package:kawula_pos/features/shifts/data/repositories/cashier_cached_shifts_repository.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';

void main() {
  late AppDatabase database;
  late CashierMasterDataCache cache;
  late _MemoryAuthLocalDataSource localDataSource;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    cache = CashierMasterDataCache(database.cachedRecordsDao);
    localDataSource = _MemoryAuthLocalDataSource();
  });

  tearDown(() async {
    await database.close();
  });

  test('online login saves the verified cashier profile snapshot', () async {
    final repository = _authRepository(
      localDataSource: localDataSource,
      cache: cache,
      profileResponse: _profile(),
    );

    final user = await repository.login(
      email: 'cashier@example.test',
      password: 'password',
    );

    expect(user.id, 'cashier-a');
    expect(user.isOfflineSession, isFalse);
    expect(localDataSource.verifiedCashierUserId, 'cashier-a');
    final cached = await cache.readCashierProfile('cashier-a');
    expect(cached, isA<Map<String, dynamic>>());
    expect(jsonEncode(cached), isNot(contains('password')));
    expect(jsonEncode(cached), isNot(contains('access_token')));
  });

  test('cashier profile and active shift restore after network loss', () async {
    final onlineAuth = _authRepository(
      localDataSource: localDataSource,
      cache: cache,
      profileResponse: _profile(),
    );
    await onlineAuth.login(email: 'cashier@example.test', password: 'password');

    final onlineShifts = CashierCachedShiftsRepository(
      _FakeShiftsRepository(activeShift: _openShift()),
      cache,
      ownerUserId: 'cashier-a',
    );
    await onlineShifts.getActive();

    final offlineAuth = _authRepository(
      localDataSource: localDataSource,
      cache: cache,
      profileError: const SocketException('network unavailable'),
    );
    final restoredUser = await offlineAuth.restoreSession();
    final offlineShifts = CashierCachedShiftsRepository(
      _FakeShiftsRepository(
        error: const SocketException('network unavailable'),
      ),
      cache,
      ownerUserId: 'cashier-a',
    );
    final restoredShift = await offlineShifts.getActive();

    expect(restoredUser?.role, 'Kasir');
    expect(restoredUser?.isOfflineSession, isTrue);
    expect(restoredShift?.id, 'shift-a');
    expect(restoredShift?.outletId, 'outlet-a');
    expect(restoredShift?.isOfflineSnapshot, isTrue);
  });

  test(
    'active shift snapshot records owner, outlet, status and verification time',
    () async {
      final repository = CashierCachedShiftsRepository(
        _FakeShiftsRepository(activeShift: _openShift()),
        cache,
        ownerUserId: 'cashier-a',
      );

      await repository.getActive();
      final snapshot = await cache.readCashierShiftSnapshot('cashier-a');

      expect(snapshot?['user_id'], 'cashier-a');
      expect(snapshot?['outlet_id'], 'outlet-a');
      expect(snapshot?['status'], 'open');
      expect(DateTime.tryParse(snapshot?['verified_at'] as String), isNotNull);
    },
  );

  test(
    'missing active shift snapshot is never treated as an open shift',
    () async {
      final repository = CashierCachedShiftsRepository(
        _FakeShiftsRepository(error: const SocketException('offline')),
        cache,
        ownerUserId: 'cashier-a',
      );

      expect(await repository.getActive(), isNull);
    },
  );

  test(
    'HTTP 401 does not restore offline and clears session credentials',
    () async {
      await _authRepository(
        localDataSource: localDataSource,
        cache: cache,
        profileResponse: _profile(),
      ).login(email: 'cashier@example.test', password: 'password');

      final repository = _authRepository(
        localDataSource: localDataSource,
        cache: cache,
        profileResponse: http.Response('{"message":"Unauthorized"}', 401),
      );
      expect(await repository.restoreSession(), isNull);
      expect(localDataSource.token, isNull);
      expect(localDataSource.verifiedCashierUserId, isNull);
    },
  );

  test('HTTP 403 does not restore from cache', () async {
    await _authRepository(
      localDataSource: localDataSource,
      cache: cache,
      profileResponse: _profile(),
    ).login(email: 'cashier@example.test', password: 'password');

    final repository = _authRepository(
      localDataSource: localDataSource,
      cache: cache,
      profileResponse: http.Response('{"message":"Forbidden"}', 403),
    );
    await expectLater(
      repository.restoreSession(),
      throwsA(isA<ApiException>()),
    );
    expect(localDataSource.verifiedCashierUserId, isNull);
  });

  test(
    'Admin profile is not restored when the server is unreachable',
    () async {
      await _authRepository(
        localDataSource: localDataSource,
        cache: cache,
        profileResponse: _profile(role: 'Admin'),
      ).login(email: 'admin@example.test', password: 'password');

      final repository = _authRepository(
        localDataSource: localDataSource,
        cache: cache,
        profileError: const SocketException('offline'),
      );
      expect(await repository.restoreSession(), isNull);
    },
  );

  test('cashier B cannot restore cashier A profile from local cache', () async {
    await _authRepository(
      localDataSource: localDataSource,
      cache: cache,
      profileResponse: _profile(),
    ).login(email: 'cashier-a@example.test', password: 'password');

    localDataSource
      ..token = 'cashier-b-token'
      ..verifiedCashierUserId = 'cashier-b';
    final repository = _authRepository(
      localDataSource: localDataSource,
      cache: cache,
      profileError: const SocketException('offline'),
    );

    expect(await repository.restoreSession(), isNull);
  });

  test(
    'logout disables local restore without deleting offline transactions',
    () async {
      await _authRepository(
        localDataSource: localDataSource,
        cache: cache,
        profileResponse: _profile(),
      ).login(email: 'cashier@example.test', password: 'password');
      final transaction = await database.offlineTransactionsDao
          .saveOfflineTransaction(
            ownerUserId: 'cashier-a',
            outletId: 'outlet-a',
            shiftId: 'shift-a',
            transactionType: 'sale',
            payload: const {'total': 100},
            receiptSnapshot: const {'receipt': 'OFF-1'},
          );

      await _authRepository(
        localDataSource: localDataSource,
        cache: cache,
        profileResponse: _profile(),
      ).logout();

      expect(localDataSource.token, isNull);
      expect(localDataSource.verifiedCashierUserId, isNull);
      expect(
        await database.offlineTransactionsDao.getTransactionByLocalId(
          transaction.localId,
        ),
        isNotNull,
      );
    },
  );

  test(
    'token without a prior verified cashier profile requires online login',
    () async {
      localDataSource.token = 'unverified-token';
      final repository = _authRepository(
        localDataSource: localDataSource,
        cache: cache,
        profileError: const SocketException('offline'),
      );

      expect(await repository.restoreSession(), isNull);
    },
  );
}

AuthRepositoryImpl _authRepository({
  required _MemoryAuthLocalDataSource localDataSource,
  required CashierMasterDataCache cache,
  http.Response? profileResponse,
  Object? profileError,
}) {
  final client = MockClient((request) async {
    if (request.url.path.endsWith('/auth/login')) {
      return http.Response(jsonEncode({'access_token': 'cashier-token'}), 200);
    }
    if (request.url.path.endsWith('/auth/me')) {
      final error = profileError;
      if (error != null) throw error;
      return profileResponse ?? _profile();
    }
    return http.Response('{}', 404);
  });
  return AuthRepositoryImpl(
    AuthRemoteDataSource(client, 'https://api.example.test'),
    localDataSource,
    masterDataCache: cache,
  );
}

http.Response _profile({String role = 'Kasir'}) => http.Response(
  jsonEncode({
    '_id': 'cashier-a',
    'name': 'Cashier A',
    'email': 'cashier@example.test',
    'role': role,
    'has_pin': true,
  }),
  200,
);

ActiveShiftModel _openShift() => ActiveShiftModel(
  id: 'shift-a',
  status: 'open',
  startTime: DateTime.utc(2026, 11, 9, 8),
  startingCash: 100000,
  expectedCash: 100000,
  totalSales: 0,
  totalTransactions: 0,
  outletId: 'outlet-a',
  outletName: 'Outlet A',
  cashierName: 'Cashier A',
);

class _MemoryAuthLocalDataSource extends AuthLocalDataSource {
  _MemoryAuthLocalDataSource() : super(const FlutterSecureStorage());

  String? token;
  String? verifiedCashierUserId;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async {
    token = value;
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }

  @override
  Future<String?> readVerifiedCashierUserId() async => verifiedCashierUserId;

  @override
  Future<void> saveVerifiedCashierUserId(String userId) async {
    verifiedCashierUserId = userId;
  }

  @override
  Future<void> clearVerifiedCashierUserId() async {
    verifiedCashierUserId = null;
  }
}

class _FakeShiftsRepository extends Fake implements ShiftsRepository {
  _FakeShiftsRepository({this.activeShift, this.error});

  final ActiveShift? activeShift;
  final Object? error;

  @override
  Future<ActiveShift?> getActive() async {
    final requestError = error;
    if (requestError != null) throw requestError;
    return activeShift;
  }
}
