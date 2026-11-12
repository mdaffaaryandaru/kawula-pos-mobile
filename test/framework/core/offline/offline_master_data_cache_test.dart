import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kawula_pos/features/products/data/repositories/offline_cached_catalog_repository.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/store_settings/data/datasources/store_settings_remote_data_source.dart';
import 'package:kawula_pos/features/store_settings/data/repositories/store_settings_repository_impl.dart';
import 'package:kawula_pos/features/transactions/data/repositories/offline_cached_checkout_repository.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/framework/core/exceptions/api_exception.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';

void main() {
  late AppDatabase database;
  late OfflineMasterDataCache cache;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    cache = OfflineMasterDataCache(database.cachedRecordsDao);
  });

  tearDown(() async {
    await database.close();
  });

  test('catalog is cached, read offline, and updated from API', () async {
    final catalog = _CatalogRepository();
    final repository = OfflineCachedCatalogRepository(
      catalog,
      _scope(cache, outletId: 'outlet-a'),
    );

    catalog.products = [_product(name: 'First')];
    expect((await repository.getProducts()).single.name, 'First');

    catalog.products = [_product(name: 'Updated')];
    expect((await repository.getProducts()).single.name, 'Updated');

    catalog.productError = const SocketException('offline');
    final offlineProducts = await repository.getProducts();
    expect(offlineProducts.single.name, 'Updated');
    expect(offlineProducts.single.discount?.value, 10);
    expect(
      offlineProducts.single.variantGroups.single.options.single.name,
      'Large',
    );
  });

  test(
    'checking uses cache until API verification restores online requests',
    () async {
      final catalog = _CatalogRepository()
        ..products = [_product(name: 'Cached')];
      final scopedCache = _scope(cache, outletId: 'outlet-a');
      final repository = OfflineCachedCatalogRepository(catalog, scopedCache);

      await repository.getProducts();
      scopedCache.markOffline();
      expect((await repository.getProducts()).single.name, 'Cached');
      expect(catalog.productRequests, 1);

      scopedCache.markChecking();
      expect(scopedCache.networkStatus, OfflineNetworkStatus.checking);
      expect((await repository.getProducts()).single.name, 'Cached');
      expect(catalog.productRequests, 1);

      catalog.products = [_product(name: 'Fresh from server')];
      scopedCache.markOnline();
      expect((await repository.getProducts()).single.name, 'Fresh from server');
      expect(catalog.productRequests, 2);
    },
  );

  test('catalog does not use cache for HTTP 400 or 401', () async {
    final catalog = _CatalogRepository()..products = [_product(name: 'Cached')];
    final repository = OfflineCachedCatalogRepository(
      catalog,
      _scope(cache, outletId: 'outlet-a'),
    );
    await repository.getProducts();

    for (final statusCode in [400, 401]) {
      final error = ApiException('HTTP $statusCode', statusCode: statusCode);
      catalog.productError = error;
      await expectLater(repository.getProducts(), throwsA(same(error)));
    }
  });

  test('cache is isolated by outlet and user', () async {
    final outletA = _scope(cache, userId: 'user-a', outletId: 'outlet-a');
    final outletB = _scope(cache, userId: 'user-a', outletId: 'outlet-b');
    final otherUser = _scope(cache, userId: 'user-b', outletId: 'outlet-a');
    final repoA = OfflineCachedCatalogRepository(
      _CatalogRepository()..products = [_product(name: 'Outlet A')],
      outletA,
    );
    final repoB = OfflineCachedCatalogRepository(
      _CatalogRepository()..products = [_product(name: 'Outlet B')],
      outletB,
    );
    final repoOtherUser = OfflineCachedCatalogRepository(
      _CatalogRepository()..products = [_product(name: 'Other user')],
      otherUser,
    );
    await repoA.getProducts();
    await repoB.getProducts();
    await repoOtherUser.getProducts();

    final offlineA = OfflineCachedCatalogRepository(
      _CatalogRepository()..productError = const SocketException('offline'),
      outletA,
    );
    final offlineB = OfflineCachedCatalogRepository(
      _CatalogRepository()..productError = const SocketException('offline'),
      outletB,
    );
    final offlineOtherUser = OfflineCachedCatalogRepository(
      _CatalogRepository()..productError = const SocketException('offline'),
      otherUser,
    );
    expect((await offlineA.getProducts()).single.name, 'Outlet A');
    expect((await offlineB.getProducts()).single.name, 'Outlet B');
    expect((await offlineOtherUser.getProducts()).single.name, 'Other user');
  });

  test('cashier auto-close settings are isolated by outlet', () async {
    final outletA = _scope(cache, outletId: 'outlet-a');
    final outletB = _scope(cache, outletId: 'outlet-b');
    await outletA.save(
      cacheType: 'cashier_store_settings',
      dataKey: 'store_settings',
      payload: {'auto_close_shift_time': '22:00'},
    );
    await outletB.save(
      cacheType: 'cashier_store_settings',
      dataKey: 'store_settings',
      payload: {'auto_close_shift_time': '23:30'},
    );

    expect(
      await outletA.read(
        cacheType: 'cashier_store_settings',
        dataKey: 'store_settings',
      ),
      {'auto_close_shift_time': '22:00'},
    );
    expect(
      await outletB.read(
        cacheType: 'cashier_store_settings',
        dataKey: 'store_settings',
      ),
      {'auto_close_shift_time': '23:30'},
    );
  });

  test('only Admin and Kasir receive a cache scope', () {
    expect(
      cache.forRole(role: 'Admin', userId: 'user-a', outletId: 'outlet-a'),
      isNotNull,
    );
    expect(
      cache.forRole(role: 'Manajer', userId: 'user-a', outletId: 'outlet-a'),
      isNull,
    );
    expect(
      cache.forRole(role: 'Kasir', userId: 'user-a', outletId: 'outlet-a'),
      isNotNull,
    );
  });

  test('cache is isolated by role as well as account and outlet', () async {
    final cashier = _scope(cache, outletId: 'outlet-a');
    final admin = cache.forRole(
      role: 'Admin',
      userId: 'cashier-1',
      outletId: 'outlet-a',
    )!;
    await cashier.save(
      cacheType: 'catalog_products',
      dataKey: 'all',
      payload: ['cashier-data'],
    );
    await admin.save(
      cacheType: 'catalog_products',
      dataKey: 'all',
      payload: ['admin-data'],
    );

    expect(await cashier.read(cacheType: 'catalog_products', dataKey: 'all'), [
      'cashier-data',
    ]);
    expect(await admin.read(cacheType: 'catalog_products', dataKey: 'all'), [
      'admin-data',
    ]);
  });

  test('checkout settings can be cached and read offline', () async {
    final checkout = _CheckoutRepository()
      ..settings = const CheckoutSettings(
        taxPercentage: 11,
        serviceCharge: 5,
        storeName: 'Kawula',
        address: 'Main Street',
      );
    final repository = OfflineCachedCheckoutRepository(
      checkout,
      _scope(cache, outletId: 'outlet-a'),
    );
    expect((await repository.getSettings()).taxPercentage, 11);

    checkout.settingsError = const SocketException('offline');
    final offlineSettings = await repository.getSettings();
    expect(offlineSettings.storeName, 'Kawula');
    expect(offlineSettings.serviceCharge, 5);
  });

  test(
    'payment methods and member search results are cached for cashier',
    () async {
      final checkout = _CheckoutRepository()
        ..paymentMethods = const [
          CheckoutPaymentMethod(name: 'Tunai', code: 'CASH'),
        ]
        ..members = const [
          Member(
            id: 'member-1',
            name: 'Member One',
            phoneNumber: '08123456789',
            currentStamps: 3,
            isActive: true,
            email: 'private@example.test',
          ),
        ];
      final repository = OfflineCachedCheckoutRepository(
        checkout,
        _scope(cache, outletId: 'outlet-a'),
      );

      expect((await repository.getPaymentMethods()).single.code, 'CASH');
      expect(
        (await repository.searchMembers('Member')).single.name,
        'Member One',
      );

      checkout.paymentMethodsError = const SocketException('offline');
      checkout.membersError = const SocketException('offline');
      expect((await repository.getPaymentMethods()).single.name, 'Tunai');
      final offlineMember = (await repository.searchMembers('Member')).single;
      expect(offlineMember.id, 'member-1');
      expect(offlineMember.email, isEmpty);
    },
  );

  test('store settings are cached after a successful API response', () async {
    final client = _SettingsHttpClient();
    final remote = StoreSettingsRemoteDataSource(
      client,
      'https://example.test/api',
      () async => 'test-token',
    );
    final repository = StoreSettingsRepositoryImpl(
      remote,
      cacheDao: database.cachedRecordsDao,
    );

    final settings = await repository.getSettings();
    expect(settings.storeName, 'Kawula Store');
    final record = await database.cachedRecordsDao.getCache(
      'store_settings',
      'global',
    );
    expect(record, isNotNull);
    expect(record!.payloadJson, contains('"auto_close_shift_enabled":true'));
  });
}

OfflineMasterDataCache _scope(
  OfflineMasterDataCache cache, {
  String userId = 'cashier-1',
  required String outletId,
}) {
  return cache.forRole(role: 'Kasir', userId: userId, outletId: outletId)!;
}

CatalogProduct _product({required String name}) => CatalogProduct(
  id: 'product-1',
  name: name,
  price: 100,
  imageUrl: '',
  isActive: true,
  category: const ProductCategory(
    id: 'category-1',
    name: 'Drinks',
    isActive: true,
  ),
  variantGroups: const [
    ProductVariantGroup(
      name: 'Size',
      isRequired: true,
      minSelection: 1,
      maxSelection: 1,
      options: [ProductVariantOption(name: 'Large', priceAdjustment: 20)],
    ),
  ],
  discount: const ProductDiscount(type: 'nominal', value: 10),
);

class _CatalogRepository implements CatalogRepository {
  List<CatalogProduct> products = [];
  Object? productError;
  int productRequests = 0;

  @override
  Future<List<CatalogProduct>> getProducts() async {
    productRequests++;
    final error = productError;
    if (error != null) throw error;
    return products;
  }

  @override
  Future<List<ProductCategory>> getCategories() async => [];
}

class _CheckoutRepository extends Fake implements CheckoutRepository {
  CheckoutSettings settings = const CheckoutSettings(
    taxPercentage: 0,
    serviceCharge: 0,
  );
  Object? settingsError;
  List<CheckoutPaymentMethod> paymentMethods = [];
  Object? paymentMethodsError;
  List<Member> members = [];
  Object? membersError;

  @override
  Future<CheckoutSettings> getSettings() async {
    final error = settingsError;
    if (error != null) throw error;
    return settings;
  }

  @override
  Future<List<CheckoutPaymentMethod>> getPaymentMethods() async {
    final error = paymentMethodsError;
    if (error != null) throw error;
    return paymentMethods;
  }

  @override
  Future<List<Member>> searchMembers(String search) async {
    final error = membersError;
    if (error != null) throw error;
    return members;
  }
}

class _SettingsHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          '{"store_name":"Kawula Store","address":"Main Street",'
          '"logo_url":"logo.png","tax_percentage":11,"service_charge":5,'
          '"auto_close_shift_enabled":true,"auto_close_shift_time":"23:00"}',
        ),
      ),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
