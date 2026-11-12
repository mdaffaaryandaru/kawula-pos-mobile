import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/products/data/models/catalog_models.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/transactions/data/models/checkout_models.dart';
import 'package:kawula_pos/features/transactions/data/repositories/offline_cached_checkout_repository.dart';
import 'package:kawula_pos/features/transactions/data/repositories/offline_checkout_repository.dart';
import 'package:kawula_pos/features/transactions/data/services/offline_transaction_sync_service.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_cubit.dart';
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_state.dart';
import 'package:kawula_pos/features/transactions/presentation/models/transaction_receipt_data.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/checkout_page.dart';
import 'package:kawula_pos/features/transactions/presentation/services/transaction_receipt_pdf.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/network/timeout_http_client.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/database/daos/offline_transactions_dao.dart';

void main() {
  late AppDatabase database;
  late OfflineMasterDataCache cache;
  late _CheckoutDelegate delegate;
  late OfflineCheckoutRepository repository;
  late CartItem item;
  var databaseClosed = false;

  AuthUser testUser({
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

  Future<void> cacheMasterData(OfflineMasterDataCache target) async {
    await target.save(
      cacheType: 'catalog_products',
      dataKey: 'all',
      payload: [CatalogProductModel.fromEntity(item.product).toJson()],
    );
    await target.save(
      cacheType: 'checkout_settings',
      dataKey: 'store',
      payload: const CheckoutSettingsModel(
        taxPercentage: 10,
        serviceCharge: 50,
        storeName: 'Kawula',
        address: 'Jl. Utama',
      ).toJson(),
    );
    await target.save(
      cacheType: 'checkout_payment_methods',
      dataKey: 'active',
      payload: const [
        CheckoutPaymentMethodModel(name: 'Tunai', code: 'CASH'),
        CheckoutPaymentMethodModel(name: 'QRIS', code: 'QRIS'),
        CheckoutPaymentMethodModel(
          name: 'Transfer Bank',
          code: 'BANK_TRANSFER',
        ),
      ].map((method) => method.toJson()).toList(),
    );
  }

  setUp(() async {
    database = AppDatabase(executor: NativeDatabase.memory());
    final rootCache = OfflineMasterDataCache(database.cachedRecordsDao);
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
    await cacheMasterData(cache);
    repository = OfflineCheckoutRepository(
      OfflineCachedCheckoutRepository(delegate, cache),
      cache,
      database.offlineTransactionsDao,
      user: testUser(),
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

  OfflineCheckoutRepository onlineRepository() => OfflineCheckoutRepository(
    OfflineCachedCheckoutRepository(delegate, cache),
    cache,
    database.offlineTransactionsDao,
    user: testUser(offline: false),
    shift: shift(offline: false),
  );

  test('saves offline cash sale with local ID, pending status and receipt snapshot', () async {
    final result = await create();
    final rows = await database.offlineTransactionsDao.getTransactionsByOwner(
      'cashier-1',
    );
    final row = rows.single;
    final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final receipt = jsonDecode(row.receiptSnapshotJson) as Map<String, dynamic>;

    expect(result.id, matches(RegExp(r'^OFF-[0-9a-f-]{36}$')));
    expect(result.status, OfflineTransactionStatus.pendingSync.databaseValue);
    expect(result.isOffline, isTrue);
    expect(result.totalAmount, 1150);
    expect(result.changeAmount, 50);
    expect(row.attemptCount, 0);
    expect(row.syncMarker, startsWith('OFFLINE_SYNC:'));
    expect(payload, {
      'outlet_id': 'outlet-1',
      'items': [
        {
          'product_id': 'product-1',
          'quantity': 1,
          'selected_variants': <Object>[],
        },
      ],
      'total_amount': 1150,
      'service_charge': 50,
      'payment_method': 'CASH',
      'paid_amount': 1200,
    });
    expect(receipt, {
      'transaction_id': result.id,
      'status': OfflineTransactionStatus.pendingSync.databaseValue,
      'store_name': 'Kawula',
      'address': 'Jl. Utama',
      'logo_url': '',
      'outlet_id': 'outlet-1',
      'outlet_name': 'Outlet Utama',
      'cashier_id': 'cashier-1',
      'cashier_name': 'Sari',
      'created_at_local': result.createdAt!.toIso8601String(),
      'items': [
        {
          'product_id': 'product-1',
          'product_name': 'Kopi',
          'quantity': 1,
          'unit_price': 1000,
          'discount_amount': 0,
          'notes': '',
          'selected_variants': <Object>[],
        },
      ],
      'subtotal': 1000,
      'tax_amount': 100,
      'service_charge': 50,
      'discount_amount': 0,
      'total_amount': 1150,
      'payment_method': 'CASH',
      'paid_amount': 1200,
      'change_amount': 50,
      'member_id': null,
      'member_name': '',
      'table_number': '',
      'sync_marker': row.syncMarker,
      'sync_status': OfflineTransactionStatus.pendingSync.databaseValue,
    });
    expect(delegate.createCalls, 0);
  });

  test('does not require or persist a PIN for offline checkout', () async {
    await expectLater(create(pin: null), completes);
    final row = (await database.offlineTransactionsDao.getTransactionsByOwner(
      'cashier-1',
    )).single;
    expect(row.payloadJson, isNot(contains('pin')));
  });

  testWidgets('offline checkout shows cached methods and online total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final checkoutCubit = CheckoutCubit(repository);
    final cartCubit = CartCubit();
    cartCubit.addProduct(item.product);
    await checkoutCubit.load();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: checkoutCubit),
          BlocProvider.value(value: cartCubit),
        ],
        child: const MaterialApp(home: CheckoutPage(outletId: 'outlet-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total estimasi'), findsOneWidget);
    expect(find.text('Rp 1.150'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('Transfer Bank'), findsOneWidget);
    await tester.tap(find.text('Transfer Bank').last);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Informasi rekening bank tidak tersedia dalam data checkout yang tersimpan.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await checkoutCubit.close();
    await cartCubit.close();
  });

  test('offline receipt PDF is generated without a logo', () async {
    final results = [
      await create(),
      await create(paymentMethod: 'OPEN_BILL', paidAmount: 0, openBill: true),
    ];
    for (final result in results) {
      final receipt = TransactionReceiptData.fromCheckout(
        result: result,
        settings: const CheckoutSettings(
          taxPercentage: 10,
          serviceCharge: 50,
          storeName: 'Kawula',
        ),
      );
      final bytes = await buildTransactionReceiptPdf(receipt).save();

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      if (result.isOpenBill) {
        expect(receipt.isPending, isTrue);
        expect(receipt.isOffline, isTrue);
      }
    }
  });

  test('verified network recovery stops treating saved session snapshots as offline', () async {
    cache.markOnline();
    delegate.createResult = const CheckoutResult(
      id: 'server-recovered',
      status: 'completed',
      totalAmount: 1150,
      paymentMethod: 'CASH',
      paidAmount: 1200,
      changeAmount: 50,
      createdAt: null,
    );

    final result = await create(pin: '1234');

    expect(result.id, 'server-recovered');
    expect(delegate.createCalls, 1);
    expect(
      await database.offlineTransactionsDao.getTransactionsByOwner('cashier-1'),
      isEmpty,
    );
  });

  test(
    'stores offline QRIS and transfer using their cached payment codes',
    () async {
      final methods = await repository.getPaymentMethods();
      expect(methods.map((method) => method.code), [
        'CASH',
        'QRIS',
        'BANK_TRANSFER',
      ]);

      for (final paymentMethod in ['QRIS', 'BANK_TRANSFER']) {
        final result = await create(
          paymentMethod: paymentMethod,
          paidAmount: 1150,
          pin: null,
        );
        final row = await database.offlineTransactionsDao
            .getTransactionByLocalId(result.id);
        final payload = jsonDecode(row!.payloadJson) as Map<String, dynamic>;
        final receipt =
            jsonDecode(row.receiptSnapshotJson) as Map<String, dynamic>;

        expect(result.id, startsWith('OFF-'));
        expect(result.status, 'pending_sync');
        expect(result.paymentMethod, paymentMethod);
        expect(result.totalAmount, 1150);
        expect(payload['payment_method'], paymentMethod);
        expect(payload['paid_amount'], 1150);
        expect(payload.containsKey('pin'), isFalse);
        expect(receipt['payment_method'], paymentMethod);
        expect(receipt['total_amount'], 1150);
        expect(row.status, 'pending_sync');
      }

      expect(delegate.createCalls, 0);
    },
  );

  test('sync forwards QRIS, transfer, and Open Bill through the online checkout contract', () async {
    await create(paymentMethod: 'QRIS', paidAmount: 1150);
    await create(paymentMethod: 'BANK_TRANSFER', paidAmount: 1150);
    await create(paymentMethod: 'OPEN_BILL', paidAmount: 0, openBill: true);

    final syncService = OfflineTransactionSyncService(
      delegate,
      database.offlineTransactionsDao,
      activeShiftsRepository: _SyncShiftRepository(shift(offline: false)),
    );
    final summary = await syncService.syncOfflineTransactions(
      ownerUserId: 'cashier-1',
      outletId: 'outlet-1',
      role: 'Kasir',
      pin: '4321',
    );

    expect(summary.successCount, 3);
    expect(
      delegate.paymentMethods,
      unorderedEquals(['QRIS', 'BANK_TRANSFER', 'OPEN_BILL']),
    );
    expect(delegate.pins, unorderedEquals(['4321', '4321', null]));
    expect(delegate.openBills, unorderedEquals([false, false, true]));
    final rows = await database.offlineTransactionsDao.getTransactionsByOwner(
      'cashier-1',
    );
    expect(rows.every((row) => row.status == 'synced'), isTrue);
  });

  test('rejects underpayment', () async {
    await expectLater(create(paidAmount: 1149), throwsA(isA<StateError>()));
  });

  test(
    'unresolved offline sales reduce estimated stock for later checkout',
    () async {
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
        await database.offlineTransactionsDao.getTransactionsByOwner(
          'cashier-1',
        ),
        hasLength(1),
      );
    },
  );

  test('rejects offline checkout when no open shift is available', () async {
    final noShiftRepository = OfflineCheckoutRepository(
      repository,
      cache,
      database.offlineTransactionsDao,
      user: testUser(),
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

  test('Admin can create an offline sale owned by the Admin account', () async {
    final adminCache = OfflineMasterDataCache(database.cachedRecordsDao)
        .forRole(role: 'Admin', userId: 'admin-1', outletId: 'outlet-1')!;
    adminCache.markOffline();
    await cacheMasterData(adminCache);
    final adminRepository = OfflineCheckoutRepository(
      OfflineCachedCheckoutRepository(delegate, adminCache),
      adminCache,
      database.offlineTransactionsDao,
      user: testUser(id: 'admin-1', role: 'Admin'),
      shift: shift(),
    );
    for (final paymentMethod in [
      'CASH',
      'QRIS',
      'BANK_TRANSFER',
      'OPEN_BILL',
    ]) {
      await adminRepository.createTransaction(
        outletId: 'outlet-1',
        items: [item],
        estimatedTotal: 1150,
        serviceCharge: 50,
        paymentMethod: paymentMethod,
        paidAmount: paymentMethod == 'OPEN_BILL' ? 0 : 1150,
        pin: null,
        openBill: paymentMethod == 'OPEN_BILL',
      );
    }
    final transactions = await database.offlineTransactionsDao
        .getTransactionsByOwner('admin-1');

    expect(transactions, hasLength(4));
    expect(
      transactions.every((transaction) => transaction.ownerUserId == 'admin-1'),
      isTrue,
    );
    expect(
      transactions.every(
        (transaction) => transaction.localId.startsWith('OFF-'),
      ),
      isTrue,
    );
    expect(
      transactions.any(
        (transaction) => transaction.transactionType == 'open_bill',
      ),
      isTrue,
    );
  });

  test('rejects checkout for management roles', () async {
    final managerRepository = OfflineCheckoutRepository(
      repository,
      cache,
      database.offlineTransactionsDao,
      user: testUser(role: 'Manajer'),
      shift: shift(),
    );
    await expectLater(
      managerRepository.createTransaction(
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
      expect(result.status, 'pending_sync');
      expect(bills.single.id, result.id);
      expect(bills.single.status, 'offline_open_bill');
      expect(bills.single.isPending, isTrue);
      final row = await database.offlineTransactionsDao.getTransactionByLocalId(
        result.id,
      );
      final payload = jsonDecode(row!.payloadJson) as Map<String, dynamic>;
      final receipt =
          jsonDecode(row.receiptSnapshotJson) as Map<String, dynamic>;
      expect(payload['payment_method'], 'OPEN_BILL');
      expect(payload['status'], 'pending');
      expect(payload.containsKey('paid_amount'), isFalse);
      expect(payload.containsKey('pin'), isFalse);
      expect(receipt['payment_method'], 'OPEN_BILL');
      expect(receipt['paid_amount'], 0);
      expect(row.status, 'pending_sync');
    },
  );

  test(
    'another cashier cannot read or create against this scoped cache',
    () async {
      await create();
      final otherCashierRepository = OfflineCheckoutRepository(
        repository,
        cache,
        database.offlineTransactionsDao,
        user: testUser(id: 'cashier-2'),
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
    },
  );

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

  test('write response timeout never enters pending sync', () async {
    cache.markOnline();
    delegate.createError = RequestOutcomeUnknownException(
      Uri.parse('https://example.test/transactions'),
    );

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
    expect(row.status, isNot('pending_sync'));
    expect(row.lastError, contains('Status transaksi belum dapat dipastikan'));
  });

  test('preserves PIN on the online path', () async {
    cache.markOnline();
    final onlineRepository = OfflineCheckoutRepository(
      OfflineCachedCheckoutRepository(delegate, cache),
      cache,
      database.offlineTransactionsDao,
      user: testUser(offline: false),
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
  final List<String> paymentMethods = <String>[];
  final List<String?> pins = <String?>[];
  final List<bool> openBills = <bool>[];
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
    paymentMethods.add(paymentMethod);
    pins.add(pin);
    openBills.add(openBill);
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

class _SyncShiftRepository implements ShiftsRepository {
  const _SyncShiftRepository(this.activeShift);

  final ActiveShift activeShift;

  @override
  Future<ActiveShift?> getActive() async => activeShift;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
