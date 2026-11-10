import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/products/data/models/catalog_models.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/transactions/data/models/checkout_models.dart';
import 'package:kawula_pos/features/transactions/data/repositories/cashier_cached_checkout_repository.dart';
import 'package:kawula_pos/features/transactions/data/repositories/cashier_offline_checkout_repository.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_cubit.dart';
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_state.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';

void main() {
  late AppDatabase database;
  late CashierMasterDataCache cache;
  late _CheckoutDelegate delegate;
  late CashierOfflineCheckoutRepository repository;
  late CartItem item;
  var databaseClosed = false;

  AuthUser cashier({
    bool offline = true,
    String id = 'cashier-1',
    String role = 'Kasir',
  }) => AuthUser(
    id: id,
    name: 'Sari',
    email: 'sari@example.com',
    role: role,
    hasPin: true,
    isOfflineSession: offline,
  );

  ActiveShift shift({bool offline = true, String status = 'open'}) =>
      ActiveShift(
        id: 'shift-1',
        status: status,
        startTime: DateTime(2025),
        startingCash: 0,
        expectedCash: 0,
        totalSales: 0,
        totalTransactions: 0,
        outletName: 'Outlet Utama',
        outletId: 'outlet-1',
        cashierName: 'Sari',
        isOfflineSnapshot: offline,
      );

  Future<void> cacheMasterData() async {
    await cache.save(
      cacheType: 'catalog_products',
      dataKey: 'all',
      payload: [CatalogProductModel.fromEntity(item.product).toJson()],
    );
    await cache.save(
      cacheType: 'checkout_settings',
      dataKey: 'store',
      payload: const CheckoutSettingsModel(
        taxPercentage: 10,
        serviceCharge: 50,
        storeName: 'Kawula',
        address: 'Jl. Utama',
      ).toJson(),
    );
    await cache.save(
      cacheType: 'checkout_payment_methods',
      dataKey: 'active',
      payload: const [
        CheckoutPaymentMethodModel(name: 'Tunai', code: 'CASH'),
        CheckoutPaymentMethodModel(name: 'QRIS', code: 'QRIS'),
      ].map((method) => method.toJson()).toList(),
    );
  }

  setUp(() async {
    database = AppDatabase(executor: NativeDatabase.memory());
    final rootCache = CashierMasterDataCache(database.cachedRecordsDao);
    cache = rootCache.forRole(
      role: 'Kasir',
      userId: 'cashier-1',
      outletId: 'outlet-1',
    )!;
    cache.markOffline();
    item = const CartItem(
      product: CatalogProduct(
        id: 'product-1',
        name: 'Kopi',
        price: 1000,
        imageUrl: '',
        isActive: true,
        category: null,
        variantGroups: [],
        stock: 5,
      ),
      quantity: 1,
      selectedVariants: [],
    );
    delegate = _CheckoutDelegate();
    await cacheMasterData();
    repository = CashierOfflineCheckoutRepository(
      CashierCachedCheckoutRepository(delegate, cache),
      cache,
      database.offlineTransactionsDao,
      user: cashier(),
      shift: shift(),
    );
  });

  tearDown(() async {
    if (!databaseClosed) await database.close();
  });

  Future<CheckoutResult> create({
    String paymentMethod = 'CASH',
    num paidAmount = 1200,
    bool openBill = false,
    String? pin,
  }) => repository.createTransaction(
    outletId: 'outlet-1',
    items: [item],
    estimatedTotal: 1,
    serviceCharge: 50,
    paymentMethod: paymentMethod,
    paidAmount: paidAmount,
    pin: pin,
    openBill: openBill,
  );

  CashierOfflineCheckoutRepository onlineRepository() =>
      CashierOfflineCheckoutRepository(
        CashierCachedCheckoutRepository(delegate, cache),
        cache,
        database.offlineTransactionsDao,
        user: cashier(offline: false),
        shift: shift(offline: false),
      );

  test(
    'saves cash sale with local ID, pending status and receipt snapshot',
    () async {
      final result = await create();
      final rows = await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      );
      final receipt =
          jsonDecode(rows.single.receiptSnapshotJson) as Map<String, dynamic>;

      expect(result.id, matches(RegExp(r'^OFF-[0-9a-f-]{36}$')));
      expect(result.status, OfflineTransactionStatus.pendingSync.databaseValue);
      expect(result.isOffline, isTrue);
      expect(result.totalAmount, 1150);
      expect(result.changeAmount, 50);
      expect(rows.single.attemptCount, 0);
      expect(rows.single.syncMarker, startsWith('OFFLINE_SYNC:'));
      expect(receipt['store_name'], 'Kawula');
      expect(receipt['outlet_name'], 'Outlet Utama');
      expect(receipt['cashier_name'], 'Sari');
      expect(receipt['created_at_local'], isA<String>());
      expect(receipt['items'].single['product_name'], 'Kopi');
      expect(receipt['total_amount'], 1150);
      expect(receipt['payment_method'], 'CASH');
      expect(receipt['paid_amount'], 1200);
      expect(receipt['change_amount'], 50);
      expect(receipt['sync_status'], 'pending_sync');
      expect(delegate.createCalls, 0);
    },
  );

  test('does not require or persist a PIN for offline checkout', () async {
    await expectLater(create(pin: null), completes);
    final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
      'cashier-1',
    )).single;
    expect(row.payloadJson, isNot(contains('pin')));
  });

  test('rejects non-cash offline payment', () async {
    await expectLater(
      create(paymentMethod: 'QRIS'),
      throwsA(isA<StateError>()),
    );
    expect(
      await database.offlineTransactionsDao.getTransactionsByOwner('cashier-1'),
      isEmpty,
    );
  });

  test('rejects underpayment', () async {
    await expectLater(create(paidAmount: 1149), throwsA(isA<StateError>()));
  });

  test('unresolved offline sales reduce estimated stock for later checkout', () async {
    await repository.createTransaction(
      outletId: 'outlet-1',
      items: [
        CartItem(
          product: item.product,
          quantity: 4,
          selectedVariants: const [],
        ),
      ],
      estimatedTotal: 4450,
      serviceCharge: 50,
      paymentMethod: 'CASH',
      paidAmount: 5000,
      pin: null,
      openBill: false,
    );

    await expectLater(
      repository.createTransaction(
        outletId: 'outlet-1',
        items: [
          CartItem(
            product: item.product,
            quantity: 2,
            selectedVariants: const [],
          ),
        ],
        estimatedTotal: 2250,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 2300,
        pin: null,
        openBill: false,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      await database.offlineTransactionsDao.getTransactionsByOwner('cashier-1'),
      hasLength(1),
    );
  });

  test('rejects offline checkout when no open shift is available', () async {
    final noShiftRepository = CashierOfflineCheckoutRepository(
      repository,
      cache,
      database.offlineTransactionsDao,
      user: cashier(),
      shift: shift(status: 'closed'),
    );
    await expectLater(
      noShiftRepository.createTransaction(
        outletId: 'outlet-1',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 1200,
        pin: null,
        openBill: false,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects a checkout for a different outlet', () async {
    await expectLater(
      repository.createTransaction(
        outletId: 'other-outlet',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 1200,
        pin: null,
        openBill: false,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects checkout for roles other than Kasir', () async {
    final adminRepository = CashierOfflineCheckoutRepository(
      repository,
      cache,
      database.offlineTransactionsDao,
      user: cashier(role: 'Admin'),
      shift: shift(),
    );
    await expectLater(
      adminRepository.createTransaction(
        outletId: 'outlet-1',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 1200,
        pin: null,
        openBill: false,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'stores offline Open Bill and returns it in the local bill list',
    () async {
      final result = await create(
        paymentMethod: 'OPEN_BILL',
        paidAmount: 0,
        openBill: true,
      );
      final bills = await repository.getTransactions();

      expect(result.isOpenBill, isTrue);
      expect(result.isOffline, isTrue);
      expect(bills.single.id, result.id);
      expect(bills.single.status, 'offline_open_bill');
      expect(bills.single.isPending, isTrue);
    },
  );

  test('another cashier cannot read or create against this scoped cache', () async {
    await create();
    final otherCashierRepository = CashierOfflineCheckoutRepository(
      repository,
      cache,
      database.offlineTransactionsDao,
      user: cashier(id: 'cashier-2'),
      shift: shift(),
    );

    expect(await otherCashierRepository.getTransactions(), isEmpty);
    await expectLater(
      otherCashierRepository.createTransaction(
        outletId: 'outlet-1',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 1200,
        pin: null,
        openBill: false,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      ),
      hasLength(1),
    );
  });

  test('does not queue HTTP business or authorization errors', () async {
    for (final status in [400, 401, 403]) {
      cache.markOnline();
      delegate.createError = ApiException('HTTP $status', statusCode: status);
      await expectLater(
        onlineRepository().createTransaction(
          outletId: 'outlet-1',
          items: [item],
          estimatedTotal: 1150,
          serviceCharge: 50,
          paymentMethod: 'CASH',
          paidAmount: 1200,
          pin: '1234',
          openBill: false,
        ),
        throwsA(isA<ApiException>()),
      );
    }
    expect(
      await database.offlineTransactionsDao.getTransactionsByOwner('cashier-1'),
      isEmpty,
    );
  });

  test(
    'marks unknown network result for reconciliation, not sync queue',
    () async {
      cache.markOnline();
      delegate.createError = const SocketException('network lost after submit');

      final result = await onlineRepository().createTransaction(
        outletId: 'outlet-1',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 1200,
        pin: '1234',
        openBill: false,
      );
      final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
        'cashier-1',
      )).single;

      expect(result.status, 'needs_reconciliation');
      expect(row.status, 'needs_reconciliation');
      expect(row.lastError, contains('network lost after submit'));
    },
  );

  test('preserves PIN on the online path', () async {
    cache.markOnline();
    final onlineRepository = CashierOfflineCheckoutRepository(
      CashierCachedCheckoutRepository(delegate, cache),
      cache,
      database.offlineTransactionsDao,
      user: cashier(offline: false),
      shift: shift(offline: false),
    );
    delegate.createResult = const CheckoutResult(
      id: 'server-1',
      status: 'paid',
      totalAmount: 1150,
      paymentMethod: 'CASH',
      paidAmount: 1200,
      changeAmount: 50,
      createdAt: null,
    );

    await onlineRepository.createTransaction(
      outletId: 'outlet-1',
      items: [item],
      estimatedTotal: 1150,
      serviceCharge: 50,
      paymentMethod: 'CASH',
      paidAmount: 1200,
      pin: '1234',
      openBill: false,
    );

    expect(delegate.lastPin, '1234');
    expect(delegate.createCalls, 1);
    expect(
      await database.offlineTransactionsDao.getTransactionsByOwner('cashier-1'),
      isEmpty,
    );
  });

  test(
    'checkout cubit prevents duplicate local records on concurrent submits',
    () async {
      final cubit = CheckoutCubit(repository);
      await cubit.load();
      final first = cubit.submit(
        outletId: 'outlet-1',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 1200,
        pin: null,
        openBill: false,
      );
      final second = cubit.submit(
        outletId: 'outlet-1',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 1200,
        pin: null,
        openBill: false,
      );
      await Future.wait([first, second]);

      expect(cubit.state, isA<CheckoutCompleted>());
      expect(
        await database.offlineTransactionsDao.getTransactionsByOwner(
          'cashier-1',
        ),
        hasLength(1),
      );
      await cubit.close();
    },
  );

  test(
    'database failure does not complete checkout or mutate cart items',
    () async {
      final cubit = CheckoutCubit(repository);
      await cubit.load();
      await database.close();
      databaseClosed = true;

      await cubit.submit(
        outletId: 'outlet-1',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: 'CASH',
        paidAmount: 1200,
        pin: null,
        openBill: false,
      );

      expect(cubit.state, isA<CheckoutReady>());
      expect(item.quantity, 1);
      await cubit.close();
    },
  );
}

class _CheckoutDelegate implements CheckoutRepository {
  int createCalls = 0;
  String? lastPin;
  Object? createError;
  CheckoutResult? createResult;

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
    createCalls++;
    lastPin = pin;
    final error = createError;
    if (error != null) throw error;
    return createResult ??
        CheckoutResult(
          id: 'server-$createCalls',
          status: 'paid',
          totalAmount: estimatedTotal,
          paymentMethod: paymentMethod,
          paidAmount: paidAmount,
          changeAmount: 0,
          createdAt: DateTime.now(),
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
