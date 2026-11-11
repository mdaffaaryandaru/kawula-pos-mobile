// Package imports:
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_navigation_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/cashier_navigation_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/cashier_tab.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/products/presentation/pages/catalog_page.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/product_management_repository.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/variant_groups/domain/repositories/variant_groups_repository.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';

void main() {
  testWidgets(
    'Admin metadata refresh preserves selected tab, cart, and shift cubit',
    (tester) async {
      final catalog = _TestCatalogRepository();
      final shifts = _TestShiftsRepository();
      final authCubit = AuthCubit(_UnusedAuthRepository());
      addTearDown(authCubit.close);

      await tester.pumpWidget(
        _adminApp(
          authCubit: authCubit,
          admin: _admin(isOffline: true),
          shifts: shifts,
          catalog: catalog,
        ),
      );
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Kasir');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kopi').last);
      await tester.pumpAndSettle();

      final originalCart = _cartCubit(tester);
      final originalShifts = _shiftsCubit(tester);
      expect(originalCart.state.quantityForProduct('coffee-id'), 1);
      expect(shifts.activeLoads, 1);

      await tester.pumpWidget(
        _adminApp(
          authCubit: authCubit,
          admin: _admin(isOffline: false, name: 'Admin terbaru'),
          shifts: shifts,
          catalog: catalog,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(find.byType(CatalogPage), findsOneWidget);
      expect(identical(_cartCubit(tester), originalCart), isTrue);
      expect(_cartCubit(tester).state.quantityForProduct('coffee-id'), 1);
      expect(identical(_shiftsCubit(tester), originalShifts), isTrue);
      expect(shifts.activeLoads, 1);
    },
  );

  testWidgets('switching Admin account clears the previous cart', (
    tester,
  ) async {
    final catalog = _TestCatalogRepository();
    final shifts = _TestShiftsRepository();
    final authCubit = AuthCubit(_UnusedAuthRepository());
    addTearDown(authCubit.close);

    await tester.pumpWidget(
      _adminApp(
        authCubit: authCubit,
        admin: _admin(),
        shifts: shifts,
        catalog: catalog,
      ),
    );
    await tester.pumpAndSettle();
    await _tapTab(tester, 'Kasir');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kopi').last);
    await tester.pumpAndSettle();
    final previousCart = _cartCubit(tester);
    expect(previousCart.state.isEmpty, isFalse);

    await tester.pumpWidget(
      _adminApp(
        authCubit: authCubit,
        admin: _admin(id: 'admin-b'),
        shifts: shifts,
        catalog: catalog,
      ),
    );
    await tester.pumpAndSettle();

    final currentCart = _cartCubit(tester);
    expect(identical(currentCart, previousCart), isFalse);
    expect(currentCart.state.isEmpty, isTrue);
    expect(previousCart.isClosed, isTrue);
    expect(shifts.activeLoads, 2);
  });

  testWidgets(
    'switching Admin outlet creates a fresh cart but keeps shift cubit',
    (tester) async {
      final catalog = _TestCatalogRepository();
      final shifts = _TestShiftsRepository();
      final authCubit = AuthCubit(_UnusedAuthRepository());
      addTearDown(authCubit.close);

      await tester.pumpWidget(
        _adminApp(
          authCubit: authCubit,
          admin: _admin(),
          shifts: shifts,
          catalog: catalog,
        ),
      );
      await tester.pumpAndSettle();
      await _tapTab(tester, 'Kasir');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kopi').last);
      await tester.pumpAndSettle();
      final previousCart = _cartCubit(tester);
      final shiftsCubit = _shiftsCubit(tester);

      shifts.outletId = 'outlet-b';
      await shiftsCubit.refreshActive();
      await tester.pumpAndSettle();

      final currentCart = _cartCubit(tester);
      expect(identical(currentCart, previousCart), isFalse);
      expect(currentCart.state.isEmpty, isTrue);
      expect(previousCart.isClosed, isTrue);
      expect(identical(_shiftsCubit(tester), shiftsCubit), isTrue);
      expect(shifts.activeLoads, 2);
    },
  );

  testWidgets('Cashier navigation still opens the sales tab', (tester) async {
    final authCubit = AuthCubit(_UnusedAuthRepository());
    addTearDown(authCubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: MaterialApp(
          home: CashierNavigationPage(
            user: _admin(id: 'cashier-a', role: 'Kasir'),
            shiftsRepository: _TestShiftsRepository(),
            catalogRepository: _TestCatalogRepository(),
            checkoutRepository: _TestCheckoutRepository(),
            balancesRepository: _UnusedBalancesRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _tapTab(tester, 'Kasir');
    await tester.pump();

    expect(find.byType(CatalogPage), findsOneWidget);
    expect(find.text('Pilih produk'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('refreshes Dashboard and Cashier only when changing tabs', (
    tester,
  ) async {
    final catalog = _TestCatalogRepository();
    final checkout = _TestCheckoutRepository();
    final shifts = _TestShiftsRepository();

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthCubit(_UnusedAuthRepository()),
        child: MaterialApp(
          home: AdminNavigationPage(
            admin: const AuthUser(
              id: 'admin-id',
              name: 'Admin',
              email: 'admin@example.test',
              role: 'Admin',
              hasPin: true,
            ),
            shiftsRepository: shifts,
            catalogRepository: catalog,
            checkoutRepository: checkout,
            balancesRepository: _UnusedBalancesRepository(),
            storeSettingsRepository: _UnusedStoreSettingsRepository(),
            apiBaseUrl: 'http://localhost/api',
            userManagementRepository: _UnusedUserManagementRepository(),
            productManagementRepository: _UnusedProductManagementRepository(),
            categoriesRepository: _UnusedCategoriesRepository(),
            variantGroupsRepository: _UnusedVariantGroupsRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(checkout.transactionLoads, 1);
    expect(shifts.activeLoads, 1);

    await _tapTab(tester, 'Kasir');
    await tester.pumpAndSettle();
    expect(catalog.productLoads, 1);
    expect(catalog.categoryLoads, 1);
    await tester.tap(find.text('Kopi').last);
    await tester.pumpAndSettle();
    expect(find.text('Keranjang (1) · Rp 10.000'), findsOneWidget);

    await _tapTab(tester, 'Manajemen');
    await tester.pumpAndSettle();
    expect(catalog.productLoads, 1);
    expect(catalog.categoryLoads, 1);
    expect(checkout.transactionLoads, 2);

    await _tapTab(tester, 'Dashboard');
    await tester.pumpAndSettle();
    expect(checkout.transactionLoads, 3);
    expect(shifts.activeLoads, 2);
    expect(find.text('Rp 30.000'), findsAtLeastNWidgets(1));

    await _tapTab(tester, 'Dashboard');
    await tester.pumpAndSettle();
    expect(checkout.transactionLoads, 3);
    expect(shifts.activeLoads, 2);

    catalog.stock = 0;
    await _tapTab(tester, 'Kasir');
    await tester.pumpAndSettle();
    expect(catalog.productLoads, 2);
    expect(catalog.categoryLoads, 2);
    expect(find.text('Keranjang (1) · Rp 10.000'), findsOneWidget);
  });

  testWidgets('Admin dashboard and management require internet access', (
    tester,
  ) async {
    final database = AppDatabase(executor: NativeDatabase.memory());
    addTearDown(database.close);
    final cache = CashierMasterDataCache(database.cachedRecordsDao)
      ..markOffline();
    final checkout = _TestCheckoutRepository();

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthCubit(_UnusedAuthRepository()),
        child: MaterialApp(
          home: AdminNavigationPage(
            admin: const AuthUser(
              id: 'admin-id',
              name: 'Admin',
              email: 'admin@example.test',
              role: 'Admin',
              hasPin: true,
            ),
            shiftsRepository: _TestShiftsRepository(),
            masterDataCache: cache,
            catalogRepository: _TestCatalogRepository(),
            checkoutRepository: checkout,
            balancesRepository: _UnusedBalancesRepository(),
            storeSettingsRepository: _UnusedStoreSettingsRepository(),
            apiBaseUrl: 'http://localhost/api',
            userManagementRepository: _UnusedUserManagementRepository(),
            productManagementRepository: _UnusedProductManagementRepository(),
            categoriesRepository: _UnusedCategoriesRepository(),
            variantGroupsRepository: _UnusedVariantGroupsRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Halaman ini memerlukan koneksi internet.'),
      findsOneWidget,
    );
    expect(checkout.transactionLoads, 0);

    await _tapTab(tester, 'Manajemen');
    await tester.pumpAndSettle();

    expect(
      find.text('Halaman ini memerlukan koneksi internet.'),
      findsOneWidget,
    );
    expect(checkout.transactionLoads, 0);
  });
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
  final index = nav.destinations
      .whereType<NavigationDestination>()
      .toList()
      .indexWhere((destination) => destination.label == label);
  if (index == -1) throw ArgumentError.value(label, 'label');
  tester
      .widget<NavigationBar>(find.byType(NavigationBar))
      .onDestinationSelected!(index);
  await tester.pumpAndSettle();
}

AuthUser _admin({
  String id = 'admin-id',
  String role = 'Admin',
  String name = 'Admin',
  bool isOffline = false,
}) => AuthUser(
  id: id,
  name: name,
  email: '$id@example.test',
  role: role,
  hasPin: true,
  isOfflineSession: isOffline,
);

CartCubit _cartCubit(WidgetTester tester) =>
    tester.element(find.byType(CatalogPage)).read<CartCubit>();

ShiftsCubit _shiftsCubit(WidgetTester tester) =>
    tester.element(find.byType(CashierTab)).read<ShiftsCubit>();

Widget _adminApp({
  required AuthCubit authCubit,
  required AuthUser admin,
  required _TestShiftsRepository shifts,
  required _TestCatalogRepository catalog,
}) => BlocProvider.value(
  value: authCubit,
  child: MaterialApp(
    home: AdminNavigationPage(
      admin: admin,
      shiftsRepository: shifts,
      catalogRepository: catalog,
      checkoutRepository: _TestCheckoutRepository(),
      balancesRepository: _UnusedBalancesRepository(),
      storeSettingsRepository: _UnusedStoreSettingsRepository(),
      apiBaseUrl: 'http://localhost/api',
      userManagementRepository: _UnusedUserManagementRepository(),
      productManagementRepository: _UnusedProductManagementRepository(),
      categoriesRepository: _UnusedCategoriesRepository(),
      variantGroupsRepository: _UnusedVariantGroupsRepository(),
    ),
  ),
);

class _TestCatalogRepository implements CatalogRepository {
  int productLoads = 0;
  int categoryLoads = 0;
  num stock = 5;

  @override
  Future<List<CatalogProduct>> getProducts() async {
    productLoads++;
    return [
      CatalogProduct(
        id: 'coffee-id',
        name: 'Kopi',
        price: 10000,
        imageUrl: '',
        isActive: true,
        category: const ProductCategory(
          id: 'category-id',
          name: 'Minuman',
          isActive: true,
        ),
        variantGroups: const [],
        stock: stock,
      ),
    ];
  }

  @override
  Future<List<ProductCategory>> getCategories() async {
    categoryLoads++;
    return const [
      ProductCategory(id: 'category-id', name: 'Minuman', isActive: true),
    ];
  }
}

class _TestCheckoutRepository implements CheckoutRepository {
  int transactionLoads = 0;

  @override
  Future<List<TransactionRecord>> getTransactions() async {
    transactionLoads++;
    return [
      TransactionRecord(
        id: 'transaction-$transactionLoads',
        status: 'completed',
        totalAmount: transactionLoads * 10000,
        paymentMethod: 'CASH',
        paidAmount: transactionLoads * 10000,
        changeAmount: 0,
        createdAt: DateTime.now(),
        items: const [],
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestShiftsRepository implements ShiftsRepository {
  int activeLoads = 0;
  String outletId = 'outlet-id';

  @override
  Future<ActiveShift?> getActive() async {
    activeLoads++;
    return ActiveShift(
      id: 'shift-id',
      status: 'active',
      startTime: DateTime.now(),
      startingCash: 0,
      expectedCash: 0,
      totalSales: 0,
      totalTransactions: activeLoads,
      outletId: outletId,
      outletName: 'Outlet',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedBalancesRepository implements BalancesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedStoreSettingsRepository implements StoreSettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedUserManagementRepository implements UserManagementRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedProductManagementRepository
    implements ProductManagementRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedCategoriesRepository implements CategoriesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedVariantGroupsRepository implements VariantGroupsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
