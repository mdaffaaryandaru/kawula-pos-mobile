import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/data/models/checkout_models.dart';
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/products/domain/entities/product_management.dart';
import 'package:kawula_pos/features/inventories/domain/entities/inventory_item.dart';
import 'package:kawula_pos/features/products/presentation/pages/products_management_page.dart';
import 'package:kawula_pos/features/variant_groups/domain/entities/variant_group_definition.dart';
import 'package:kawula_pos/features/variant_groups/domain/repositories/variant_groups_repository.dart';
import 'package:kawula_pos/features/variant_groups/presentation/pages/variant_groups_management_page.dart';
import 'package:kawula_pos/features/categories/domain/entities/managed_category.dart';
import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/product_management_repository.dart';
import 'package:kawula_pos/features/balances/domain/entities/balance.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/balances/presentation/pages/balances_admin_page.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_transaction_report_page.dart';
import 'package:kawula_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/store_settings/presentation/pages/store_settings_page.dart';
import 'package:kawula_pos/features/shifts/domain/entities/admin_shift_detail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kawula_pos/main.dart';

void main() {
  testWidgets('loads and saves backend store settings', (tester) async {
    final repository = _FakeStoreSettingsRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: StoreSettingsPage(
          repository: repository,
          apiBaseUrl: 'http://localhost:3001/api',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan toko'), findsOneWidget);
    expect(find.text('Kawula Cafe'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('store-settings-name')),
      'Kawula Store Baru',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tutup shift otomatis'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tutup shift otomatis'), findsOneWidget);
    await tester.dragFrom(const Offset(400, 500), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-settings-save')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('store-settings-save')));
    await tester.pumpAndSettle();

    expect(repository.savedSettings?.storeName, 'Kawula Store Baru');
    expect(repository.savedSettings?.taxPercentage, 10);
    expect(repository.savedSettings?.autoCloseShiftEnabled, isTrue);
    expect(find.text('Pengaturan toko berhasil disimpan.'), findsOneWidget);
  });

  testWidgets(
    'reports completed sales separately from open bills and expenses',
    (tester) async {
      final checkoutRepository = _FakeCheckoutRepository();
      checkoutRepository.transactions
        ..clear()
        ..addAll([
          TransactionRecord(
            id: 'completed-id',
            status: 'completed',
            totalAmount: 5000,
            paymentMethod: 'CASH',
            paidAmount: 5000,
            changeAmount: 0,
            createdAt: DateTime.now(),
            items: const [
              TransactionRecordItem(
                productName: 'Kopi',
                quantity: 1,
                price: 5000,
              ),
            ],
            cogs: 2000,
          ),
          TransactionRecord(
            id: 'pending-id',
            status: 'pending',
            totalAmount: 3000,
            paymentMethod: 'OPEN_BILL',
            paidAmount: 0,
            changeAmount: 0,
            createdAt: DateTime.now(),
            items: const [],
          ),
        ]);
      final balancesRepository = _FakeBalancesRepository(
        history: [
          BalanceHistoryEntry(
            id: 'expense-id',
            paymentMethod: 'CASH',
            type: 'expense',
            amount: -1000,
            finalBalance: 0,
            notes: 'Operasional',
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdminTransactionReportPage(
            checkoutRepository: checkoutRepository,
            balancesRepository: balancesRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OMZET PENJUALAN'), findsOneWidget);
      expect(find.textContaining('OPEN BILL / TRANSAKSI'), findsOneWidget);
      expect(find.text('LABA BERSIH'), findsOneWidget);
      expect(find.text('Rp 5.000'), findsOneWidget);
      expect(find.text('Rp 3.000'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('HPP / Modal Bahan'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('HPP / Modal Bahan'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Operasional · CASH'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Operasional · CASH'), findsOneWidget);
    },
  );

  testWidgets('records an operational expense from the report page', (
    tester,
  ) async {
    final balancesRepository = _FakeBalancesRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminTransactionReportPage(
          checkoutRepository: _FakeCheckoutRepository(),
          balancesRepository: balancesRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catat Biaya'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Belanja Gas');
    await tester.enterText(find.byType(TextFormField).at(1), '50000');
    await tester.tap(find.text('Simpan biaya'));
    await tester.pumpAndSettle();

    expect(balancesRepository.recordedExpenseNotes, 'Belanja Gas');
    expect(balancesRepository.recordedExpenseAmount, 50000);
    expect(balancesRepository.recordedExpenseMethod, 'CASH');
  });

  testWidgets(
    'shows variant groups before loading optional recipe references',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VariantGroupsManagementPage(
            repository: _VariantGroupsReferencesUnavailableRepository(),
            productsRepository: _FakeProductManagementRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ukuran'), findsOneWidget);
      expect(find.text('Min/Max: 1 - 1 pilihan'), findsOneWidget);
    },
  );

  testWidgets('keeps products visible when variant groups fail to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsManagementPage(
          repository: _VariantGroupsUnavailableProductRepository(),
          variantGroupsRepository: _FakeVariantGroupsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kopi Susu'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(find.textContaining('Grup varian:'), findsOneWidget);
  });

  testWidgets('separates table actions and avoids narrow-screen overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ProductsManagementPage(
          repository: _RecipeProductRepository(),
          variantGroupsRepository: _FakeVariantGroupsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final recipeButton = tester.getRect(find.text('Bahan (0)'));
    final deleteButton = tester.getRect(find.byTooltip('Hapus produk'));
    expect(recipeButton.right, lessThan(deleteButton.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a product from the redesigned responsive dialog', (
    tester,
  ) async {
    final repository = _ProductDialogTestRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsManagementPage(
          repository: repository,
          variantGroupsRepository: _FakeVariantGroupsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah Product'));
    await tester.pumpAndSettle();

    expect(find.text('Informasi produk'), findsOneWidget);
    expect(find.text('Galeri produk'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextFormField).at(0), 'Cappuccino');
    await tester.enterText(find.byType(TextFormField).at(1), '24000');
    await tester.enterText(find.byType(TextFormField).at(2), '30');
    await tester.tap(find.text('Simpan produk'));
    await tester.pumpAndSettle();

    expect(repository.savedName, 'Cappuccino');
    expect(repository.savedPrice, 24000);
    expect(repository.savedStock, 30);
  });

  testWidgets('opens and saves the same redesigned dialog for product edits', (
    tester,
  ) async {
    final repository = _ProductDialogTestRepository(withExistingProduct: true);
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsManagementPage(
          repository: repository,
          variantGroupsRepository: _FakeVariantGroupsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Ubah produk'), findsOneWidget);
    expect(find.text('Galeri produk'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      'Cappuccino',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '25000');
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();

    expect(repository.savedProductId, 'existing-product-id');
    expect(repository.savedPrice, 25000);
  });

  testWidgets('adds a recipe using the selected inventory unit', (
    tester,
  ) async {
    final repository = _RecipeProductRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsManagementPage(
          repository: repository,
          variantGroupsRepository: _FakeVariantGroupsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bahan (0)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '15');
    await tester.tap(find.text('Tambah Bahan'));
    await tester.pumpAndSettle();

    expect(repository.addedInventoryId, 'inventory-id');
    expect(repository.addedQuantity, 15);
    expect(repository.addedUnitId, 'portion-id');
    expect(repository.addedConversionFactor, 1);
    expect(find.text('Total bahan 1 item'), findsOneWidget);
    expect(find.text('Rp 30'), findsOneWidget);
  });

  testWidgets('creates and deletes a variant group using its form', (
    tester,
  ) async {
    final repository = _FakeVariantGroupsRepository();
    final productsRepository = _FakeProductManagementRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: VariantGroupsManagementPage(
          repository: repository,
          productsRepository: productsRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada grup varian'), findsOneWidget);
    await tester.tap(find.text('Tambah Grup Varian'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ukuran');
    await tester.enterText(find.byType(TextFormField).at(3), 'Large');
    await tester.enterText(find.byType(TextFormField).at(4), '5000');
    await tester.tap(find.text('Buat grup'));
    await tester.pumpAndSettle();

    expect(repository.variantGroupDefinitions.single.name, 'Ukuran');
    expect(
      repository.variantGroupDefinitions.single.options.single.name,
      'Large',
    );
    expect(find.text('Ukuran'), findsOneWidget);

    expect(find.text('Min/Max: 0 - 1 pilihan'), findsOneWidget);
    expect(find.textContaining('Large (+Rp 5.000)'), findsOneWidget);
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();

    expect(repository.variantGroupDefinitions, isEmpty);
    expect(find.text('Belum ada grup varian'), findsOneWidget);
  });

  testWidgets('shows finance balances and signed history amounts', (
    tester,
  ) async {
    final balancesRepository = _FakeBalancesRepository(
      balances: const [
        BalanceAccount(id: 'cash-id', paymentMethod: 'CASH', balance: 150000),
      ],
      history: [
        BalanceHistoryEntry(
          id: 'expense-id',
          paymentMethod: 'CASH',
          type: 'expense',
          amount: -25000,
          finalBalance: 150000,
          notes: 'Belanja operasional',
          createdAt: DateTime(2026, 10, 28, 9),
          createdBy: 'Admin Kawula',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BalancesAdminPage(
          repository: balancesRepository,
          checkoutRepository: _FakeCheckoutRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Keseluruhan'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsNWidgets(2));
    expect(find.text('Cash (CASH)'), findsOneWidget);
    expect(find.text('PENGELUARAN'), findsOneWidget);
    expect(find.text('- Rp 25.000'), findsOneWidget);
    expect(find.textContaining('Belanja operasional'), findsOneWidget);
    expect(find.text('Saldo akhir Rp 150.000'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'tidak-ditemukan');
    await tester.pumpAndSettle();
    expect(find.text('Belanja operasional'), findsNothing);
    expect(
      find.text('Tidak ada mutasi yang cocok dengan pencarian.'),
      findsOneWidget,
    );
  });

  testWidgets('routes admin to dashboard and exposes admin features', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository(role: 'Admin');
    final shiftsRepository = _FakeShiftsRepository();
    final userManagementRepository = _FakeUserManagementRepository();
    final categoriesRepository = _FakeCategoriesRepository();
    final checkoutRepository = _FakeCheckoutRepository();
    final now = DateTime.now();
    checkoutRepository.transactions.addAll([
      TransactionRecord(
        id: 'completed-ABC123',
        status: 'completed',
        totalAmount: 50000,
        paymentMethod: 'CASH',
        paidAmount: 50000,
        changeAmount: 0,
        createdAt: now,
        items: const [
          TransactionRecordItem(productName: 'Kopi', quantity: 2, price: 25000),
        ],
      ),
      TransactionRecord(
        id: 'pending-DEF456',
        status: 'pending',
        totalAmount: 25000,
        paymentMethod: 'OPEN_BILL',
        paidAmount: 0,
        changeAmount: 0,
        createdAt: now,
        items: const [
          TransactionRecordItem(productName: 'Teh', quantity: 1, price: 25000),
        ],
      ),
    ]);

    await tester.pumpWidget(
      KawulaPosApp(
        apiBaseUrl: 'http://localhost:3001/api',
        authRepository: authRepository,
        shiftsRepository: shiftsRepository,
        catalogRepository: _FakeCatalogRepository(),
        checkoutRepository: checkoutRepository,
        balancesRepository: _FakeBalancesRepository(),
        storeSettingsRepository: _FakeStoreSettingsRepository(),
        userManagementRepository: userManagementRepository,
        productManagementRepository: _FakeProductManagementRepository(),
        categoriesRepository: categoriesRepository,
        variantGroupsRepository: _FakeVariantGroupsRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@kawula.id');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Manajemen Cepat'), findsNothing);
    expect(find.text('Pendapatan Hari Ini'), findsOneWidget);
    expect(find.text('Transaksi Selesai'), findsOneWidget);
    expect(find.text('Open Bill Aktif'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsNWidgets(2));
    expect(find.text('Transaksi Terbaru'), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final destination in ['Dashboard', 'Kasir', 'Manajemen']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(destination),
        ),
        findsOneWidget,
      );
    }
    expect(shiftsRepository.activeChecks, 1);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Manajemen'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Laporan transaksi'), findsOneWidget);
    expect(find.text('Keuangan'), findsOneWidget);
    expect(find.text('Pemantauan shift'), findsOneWidget);
    expect(find.text('Produk'), findsOneWidget);
    expect(find.text('Grup varian'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Pengaturan toko'), findsOneWidget);
    expect(find.text('Pengaturan kasir'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    await tester.ensureVisible(find.text('Pengaturan toko'));
    await tester.tap(find.text('Pengaturan toko'));
    await tester.pumpAndSettle();
    expect(find.text('Identitas toko'), findsOneWidget);
    expect(find.text('Biaya transaksi'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Grup varian'));
    await tester.tap(find.text('Grup varian'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada grup varian'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Dashboard'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey<String>('admin-dashboard-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transaksi Baru · Buka Kasir'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada shift aktif'), findsWidgets);
    expect(shiftsRepository.activeChecks, 1);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Manajemen'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Keuangan'));
    await tester.tap(find.text('Keuangan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada saldo tercatat.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pemantauan shift'));
    await tester.tap(find.text('Pemantauan shift'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada shift pada filter ini.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pengaturan kasir'));
    await tester.tap(find.text('Pengaturan kasir'));
    await tester.pumpAndSettle();
    expect(
      find.text('kasirbaru@kawula.id\nKasir · PIN belum diatur'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Atur PIN Kasir Baru'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'PIN baru',
      ),
      '5678',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Ulangi PIN',
      ),
      '5678',
    );
    await tester.tap(find.text('Simpan PIN'));
    await tester.pumpAndSettle();

    expect(userManagementRepository.updatedUserId, 'cashier-id');
    expect(userManagementRepository.updatedPin, '5678');
    expect(
      find.text('kasirbaru@kawula.id\nKasir · PIN sudah diatur'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kategori'));
    await tester.tap(find.text('Kategori'));
    await tester.pumpAndSettle();
    expect(find.text('Kategori'), findsOneWidget);
    await tester.tap(find.text('Tambah kategori'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Makanan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Menu makanan');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Makanan'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Keluar'));
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Kawula POS'), findsOneWidget);
  });

  testWidgets('logs in and logs out through the authentication gate', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final shiftsRepository = _FakeShiftsRepository();
    final catalogRepository = _FakeCatalogRepository();
    final checkoutRepository = _FakeCheckoutRepository();

    await tester.pumpWidget(
      KawulaPosApp(
        apiBaseUrl: 'http://localhost:3001/api',
        authRepository: repository,
        shiftsRepository: shiftsRepository,
        catalogRepository: catalogRepository,
        checkoutRepository: checkoutRepository,
        balancesRepository: _FakeBalancesRepository(),
        storeSettingsRepository: _FakeStoreSettingsRepository(),
        userManagementRepository: _FakeUserManagementRepository(),
        productManagementRepository: _FakeProductManagementRepository(),
        categoriesRepository: _FakeCategoriesRepository(),
        variantGroupsRepository: _FakeVariantGroupsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke Kawula POS'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'kasir@kawula.id');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada shift aktif'), findsOneWidget);
    expect(repository.lastEmail, 'kasir@kawula.id');

    await tester.enterText(find.byType(TextFormField).at(0), '50000');
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.tap(find.text('Buka shift'));
    await tester.pumpAndSettle();

    expect(find.text('Shift sedang berjalan'), findsOneWidget);
    expect(shiftsRepository.openedWithCash, 50000);

    await tester.tap(find.text('Ke kasir'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih produk'), findsOneWidget);
    expect(find.text('Shift Aktif'), findsOneWidget);
    expect(find.text('Tutup Shift'), findsOneWidget);
    expect(find.textContaining('Kopi Susu'), findsOneWidget);
    await tester.tap(find.text('Tutup Shift'));
    await tester.pumpAndSettle();
    expect(find.text('Shift sedang berjalan'), findsOneWidget);

    await tester.tap(find.text('Ke kasir'));
    await tester.pumpAndSettle();
    expect(find.text('Shift Aktif'), findsOneWidget);

    await tester.tap(find.text('Kopi Susu'));
    await tester.pumpAndSettle();
    expect(find.text('Keranjang (1) · Rp 18.000'), findsOneWidget);

    await tester.tap(find.text('Keranjang (1) · Rp 18.000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah catatan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'tanpa gula');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan: tanpa gula'), findsOneWidget);
    await tester.tap(find.text('Lanjut ke pembayaran'));
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan pesanan'), findsOneWidget);
    final memberSearch = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Cari nama atau nomor telepon',
    );
    await tester.enterText(memberSearch, '0812');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Siti Member'), findsOneWidget);
    expect(find.text('Member Nonaktif'), findsNothing);
    await tester.tap(find.text('Siti Member'));
    await tester.pumpAndSettle();
    expect(find.text('Siti Member · 08123456789'), findsOneWidget);
    final paymentMethodDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.dragFrom(const Offset(400, 500), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(paymentMethodDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tunai').last);
    await tester.pumpAndSettle();
    final cashField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Uang diterima',
    );
    expect(cashField, findsOneWidget);
    await tester.enterText(cashField, '20000');
    await tester.dragFrom(const Offset(400, 500), const Offset(0, -600));
    await tester.pumpAndSettle();
    final pinField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'PIN kasir',
    );
    expect(pinField, findsOneWidget);
    await tester.enterText(pinField, '1234');
    await tester.ensureVisible(find.text('Bayar Rp 19.800'));
    await tester.tap(find.text('Bayar Rp 19.800'));
    await tester.pumpAndSettle();

    expect(checkoutRepository.submittedOutletId, 'outlet-id');
    expect(checkoutRepository.submittedMemberId, 'member-id');
    expect(find.text('Pembayaran berhasil'), findsOneWidget);
    expect(find.text('STRUK PEMBAYARAN'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Siti Member · 08123456789'), findsOneWidget);
    expect(find.text('Kawula Store'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Pajak'), findsOneWidget);
    expect(find.textContaining('Kopi Susu'), findsOneWidget);
    expect(find.text('Catatan: tanpa gula'), findsOneWidget);
    expect(find.text('Bagikan struk'), findsOneWidget);
    expect(checkoutRepository.submittedTotal, 19800);
    expect(checkoutRepository.submittedPaidAmount, 20000);
    expect(checkoutRepository.submittedPin, '1234');
    expect(checkoutRepository.submittedItems?.single.product.id, 'product-id');
    expect(checkoutRepository.submittedItems?.single.notes, 'tanpa gula');

    await tester.ensureVisible(find.text('Kembali ke katalog'));
    await tester.tap(find.text('Kembali ke katalog'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buka keranjang'));
    await tester.pumpAndSettle();
    expect(find.text('Keranjang (0)'), findsOneWidget);
    expect(find.text('Keranjang masih kosong.'), findsOneWidget);
    await tester.tap(find.byTooltip('Tutup keranjang'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Riwayat transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Semua (1)'), findsOneWidget);
    await tester.tap(find.text('Open bill (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rp 25.000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunasi open bill'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Uang diterima',
      ),
      '30000',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'PIN kasir',
      ),
      '1234',
    );
    await tester.tap(find.text('Konfirmasi pelunasan'));
    await tester.pumpAndSettle();
    expect(find.text('Open bill (0)'), findsOneWidget);
    await tester.tap(find.text('Semua (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Lunas'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Tutup shift'));
    await tester.tap(find.text('Tutup shift'));
    await tester.pumpAndSettle();
    expect(find.text('Kas aktual'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextFormField).at(0));
    await tester.enterText(find.byType(TextFormField).at(0), '48000');
    await tester.ensureVisible(find.byType(TextFormField).at(1));
    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.ensureVisible(find.text('Lanjutkan tutup shift'));
    await tester.tap(find.text('Lanjutkan tutup shift'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi tutup shift'), findsOneWidget);
    expect(find.text('- Rp 2.000'), findsOneWidget);
    await tester.tap(find.text('Ya, tutup shift'));
    await tester.pumpAndSettle();

    expect(find.text('Shift berhasil ditutup'), findsOneWidget);
    expect(shiftsRepository.closedWithCash, 48000);

    await tester.tap(find.byTooltip('Keluar'));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke Kawula POS'), findsOneWidget);
  });
}

class _FakeShiftsRepository implements ShiftsRepository {
  var isOpen = false;
  var activeChecks = 0;
  num? openedWithCash;
  num? closedWithCash;

  @override
  Future<ActiveShift?> getActive() async {
    activeChecks++;
    if (!isOpen) return null;
    return ActiveShift(
      id: 'shift-id',
      status: 'open',
      startTime: DateTime(2026, 10, 27, 9),
      startingCash: openedWithCash ?? 0,
      expectedCash: openedWithCash ?? 0,
      totalSales: 0,
      totalTransactions: 0,
      outletName: 'Outlet Utama',
      outletId: 'outlet-id',
    );
  }

  @override
  Future<CashAvailability> getCashAvailability() async {
    return const CashAvailability(
      globalBalance: 100000,
      reservedCash: 0,
      availableCash: 100000,
    );
  }

  @override
  Future<void> openShift({
    required num startingCash,
    required String pin,
  }) async {
    expect(pin, '1234');
    openedWithCash = startingCash;
    isOpen = true;
  }

  @override
  Future<ActiveShift> closeShift({
    required String shiftId,
    required num actualCash,
    String? pin,
    String? notes,
  }) async {
    expect(shiftId, 'shift-id');
    expect(pin, '1234');
    closedWithCash = actualCash;
    isOpen = false;
    return ActiveShift(
      id: shiftId,
      status: 'closed',
      startTime: DateTime(2026, 10, 27, 9),
      endTime: DateTime(2026, 10, 27, 17),
      startingCash: openedWithCash ?? 0,
      expectedCash: openedWithCash ?? 0,
      actualCash: actualCash,
      cashDifference: actualCash - (openedWithCash ?? 0),
      totalSales: 0,
      totalTransactions: 0,
    );
  }

  @override
  Future<List<ActiveShift>> getShifts({String? status}) async => [];

  @override
  Future<AdminShiftDetail> getShiftDetail(String shiftId) async =>
      throw UnimplementedError();

  @override
  Future<ActiveShift> forceCloseShift({
    required String shiftId,
    required num actualCash,
    required String notes,
  }) async => throw UnimplementedError();
}

class _FakeStoreSettingsRepository implements StoreSettingsRepository {
  StoreSettings? savedSettings;

  StoreSettings _settings = const StoreSettings(
    storeName: 'Kawula Cafe',
    address: 'Jl. Kopi',
    logoUrl: '',
    taxPercentage: 10,
    serviceCharge: 0,
    autoCloseShiftEnabled: true,
    autoCloseShiftTime: '00:00',
  );

  @override
  Future<StoreSettings> getSettings() async => _settings;

  @override
  Future<StoreSettings> updateSettings(StoreSettings settings) async {
    savedSettings = settings;
    _settings = settings;
    return settings;
  }

  @override
  Future<String> uploadLogo(XFile image) async => '/uploads/store/logo.png';
}

class _FakeBalancesRepository implements BalancesRepository {
  _FakeBalancesRepository({this.balances = const [], this.history = const []});

  final List<BalanceAccount> balances;
  final List<BalanceHistoryEntry> history;
  String? recordedExpenseNotes;
  String? recordedExpenseMethod;
  num? recordedExpenseAmount;

  @override
  Future<List<BalanceAccount>> getBalances() async => balances;

  @override
  Future<List<BalanceHistoryEntry>> getHistory() async => history;

  @override
  Future<void> recordExpense({
    required String paymentMethod,
    required num amount,
    required String notes,
  }) async {
    recordedExpenseMethod = paymentMethod;
    recordedExpenseAmount = amount;
    recordedExpenseNotes = notes;
  }

  @override
  Future<void> adjustBalance({
    required String paymentMethod,
    required num actualBalance,
    required String notes,
  }) async {}
}

class _FakeCheckoutRepository implements CheckoutRepository {
  String? submittedOutletId;
  String? submittedMemberId;
  num? submittedTotal;
  num? submittedPaidAmount;
  String? submittedPin;
  List<CartItem>? submittedItems;
  final List<TransactionRecord> transactions = [
    TransactionRecord(
      id: 'pending-id',
      status: 'pending',
      totalAmount: 25000,
      paymentMethod: 'OPEN_BILL',
      paidAmount: 0,
      changeAmount: 0,
      createdAt: DateTime(2026, 10, 27, 9),
      items: const [
        TransactionRecordItem(
          productName: 'Kopi Susu',
          quantity: 1,
          price: 25000,
          notes: 'panas',
        ),
      ],
    ),
  ];

  @override
  Future<CheckoutResult> createTransaction({
    required String outletId,
    required List<CartItem> items,
    required num estimatedTotal,
    required String paymentMethod,
    required num paidAmount,
    required String? pin,
    required bool openBill,
    String? memberId,
  }) async {
    submittedOutletId = outletId;
    submittedMemberId = memberId;
    submittedTotal = estimatedTotal;
    submittedPaidAmount = paidAmount;
    submittedPin = pin;
    submittedItems = items;
    return CheckoutResult(
      id: 'transaction-id',
      status: openBill ? 'pending' : 'completed',
      totalAmount: estimatedTotal,
      paymentMethod: openBill ? 'OPEN_BILL' : paymentMethod,
      paidAmount: openBill ? 0 : paidAmount,
      changeAmount: openBill ? 0 : paidAmount - estimatedTotal,
      createdAt: DateTime(2026, 10, 27, 9),
      subtotal: estimatedTotal,
      taxAmount: 0,
      serviceCharge: 0,
      discountAmount: 0,
      items: items
          .map(
            (item) => CheckoutResultItem(
              productName: item.product.name,
              quantity: item.quantity,
              price: item.unitPrice,
              selectedVariants: item.selectedVariants
                  .map(
                    (variant) => CheckoutResultVariant(
                      groupName: variant.groupName,
                      optionName: variant.optionName,
                    ),
                  )
                  .toList(),
              notes: item.notes,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<List<CheckoutPaymentMethod>> getPaymentMethods() async =>
      const <CheckoutPaymentMethodModel>[
        CheckoutPaymentMethodModel(name: 'Tunai', code: 'CASH'),
        CheckoutPaymentMethodModel(name: 'QRIS', code: 'QRIS'),
      ];

  @override
  Future<List<TransactionRecord>> getTransactions() async => transactions;

  @override
  Future<List<Member>> searchMembers(String search) async => [
    const Member(
      id: 'member-id',
      name: 'Siti Member',
      phoneNumber: '08123456789',
      currentStamps: 2,
      isActive: true,
    ),
    const Member(
      id: 'inactive-member-id',
      name: 'Member Nonaktif',
      phoneNumber: '08111111111',
      currentStamps: 0,
      isActive: false,
    ),
  ];

  @override
  Future<CheckoutResult> payPendingTransaction({
    required String transactionId,
    required String paymentMethod,
    required num paidAmount,
    required String pin,
  }) async {
    expect(pin, '1234');
    final index = transactions.indexWhere((item) => item.id == transactionId);
    final pending = transactions[index];
    final settled = TransactionRecord(
      id: pending.id,
      status: 'completed',
      totalAmount: pending.totalAmount,
      paymentMethod: paymentMethod,
      paidAmount: paidAmount,
      changeAmount: paymentMethod == 'CASH'
          ? paidAmount - pending.totalAmount
          : 0,
      createdAt: pending.createdAt,
      items: pending.items,
      notes: pending.notes,
    );
    transactions[index] = settled;
    return CheckoutResult(
      id: settled.id,
      status: settled.status,
      totalAmount: settled.totalAmount,
      paymentMethod: settled.paymentMethod,
      paidAmount: settled.paidAmount,
      changeAmount: settled.changeAmount,
      createdAt: settled.createdAt,
    );
  }

  @override
  Future<CheckoutSettings> getSettings() async => const CheckoutSettings(
    taxPercentage: 10,
    serviceCharge: 0,
    storeName: 'Kawula Store',
    address: 'Jl. Kasir 1',
  );
}

class _FakeCatalogRepository implements CatalogRepository {
  @override
  Future<List<ProductCategory>> getCategories() async {
    return const [
      ProductCategory(id: 'category-id', name: 'Minuman', isActive: true),
    ];
  }

  @override
  Future<List<CatalogProduct>> getProducts() async {
    return const [
      CatalogProduct(
        id: 'product-id',
        name: 'Kopi Susu',
        price: 18000,
        imageUrl: '',
        isActive: true,
        category: ProductCategory(
          id: 'category-id',
          name: 'Minuman',
          isActive: true,
        ),
        variantGroups: [],
      ),
    ];
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.role = 'Kasir'});

  final String role;
  String? lastEmail;
  var isLoggedIn = false;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    isLoggedIn = true;
    return AuthUser(
      id: 'user-id',
      name: 'Kasir Kawula',
      email: 'kasir@kawula.id',
      role: role,
      hasPin: true,
    );
  }

  @override
  Future<AuthUser?> restoreSession() async {
    if (!isLoggedIn) return null;
    return AuthUser(
      id: 'user-id',
      name: 'Kasir Kawula',
      email: 'kasir@kawula.id',
      role: role,
      hasPin: true,
    );
  }

  @override
  Future<void> logout() async {
    isLoggedIn = false;
  }
}

class _FakeUserManagementRepository implements UserManagementRepository {
  String? updatedUserId;
  String? updatedPin;

  @override
  Future<List<AuthUser>> getUsers() async => const [
    AuthUser(
      id: 'admin-id',
      name: 'Admin',
      email: 'admin@kawula.id',
      role: 'Admin',
      hasPin: false,
    ),
    AuthUser(
      id: 'cashier-id',
      name: 'Kasir Baru',
      email: 'kasirbaru@kawula.id',
      role: 'Kasir',
      hasPin: false,
    ),
  ];

  @override
  Future<AuthUser> updatePin({
    required String userId,
    required String pin,
  }) async {
    updatedUserId = userId;
    updatedPin = pin;
    return AuthUser(
      id: userId,
      name: userId == 'cashier-id' ? 'Kasir Baru' : 'Admin',
      email: userId == 'cashier-id' ? 'kasirbaru@kawula.id' : 'admin@kawula.id',
      role: userId == 'cashier-id' ? 'Kasir' : 'Admin',
      hasPin: true,
    );
  }
}

class _FakeProductManagementRepository implements ProductManagementRepository {
  @override
  Future<List<String>> uploadProductImages(List<XFile> images) async =>
      images.map((image) => '/uploads/products/${image.name}').toList();

  @override
  Future<List<ManagedCategory>> getCategories() async => const [];

  @override
  Future<List<ManagedProduct>> getProducts() async => const [];

  @override
  Future<List<ManagedVariantGroup>> getVariantGroups() async => const [];

  @override
  Future<List<InventoryItem>> getInventories() async => const [];

  @override
  Future<List<ProductUnit>> getProductUnits() async => const [];

  @override
  Future<ManagedProduct> saveProduct({
    String? productId,
    required String name,
    required num price,
    required num stock,
    required String categoryId,
    required List<String> variantGroupIds,
    required List<ProductImage> images,
    required bool isActive,
  }) async => ManagedProduct(
    product: CatalogProduct(
      id: productId ?? 'product-id',
      name: name,
      price: price,
      stock: stock,
      imageUrl: '',
      isActive: isActive,
      category: ProductCategory(
        id: categoryId,
        name: 'Kategori',
        isActive: true,
      ),
      variantGroups: const [],
    ),
    variantGroupIds: variantGroupIds,
  );

  @override
  Future<void> deleteProduct(String productId) async {}

  @override
  Future<void> addRecipe({
    required String productId,
    required String inventoryId,
    required num quantity,
    required String unitId,
    required num conversionFactor,
  }) async {}

  @override
  Future<void> removeRecipe({
    required String productId,
    required int recipeIndex,
  }) async {}
}

class _VariantGroupsUnavailableProductRepository
    extends _FakeProductManagementRepository {
  @override
  Future<List<ManagedProduct>> getProducts() async => [
    ManagedProduct(
      product: const CatalogProduct(
        id: 'coffee-id',
        name: 'Kopi Susu',
        price: 18000,
        imageUrl: '',
        isActive: true,
        category: null,
        variantGroups: [],
      ),
      variantGroupIds: [],
    ),
  ];

  @override
  Future<List<ManagedVariantGroup>> getVariantGroups() {
    throw Exception('server grup varian tidak tersedia');
  }
}

class _RecipeProductRepository extends _FakeProductManagementRepository {
  String? addedInventoryId;
  num? addedQuantity;
  String? addedUnitId;
  num? addedConversionFactor;

  @override
  Future<List<ManagedProduct>> getProducts() async => [
    ManagedProduct(
      product: const CatalogProduct(
        id: 'product-id',
        name: 'Kopi Susu',
        price: 18000,
        imageUrl: '',
        isActive: true,
        category: null,
        variantGroups: [],
      ),
      variantGroupIds: [],
    ),
  ];

  @override
  Future<List<InventoryItem>> getInventories() async => const [
    InventoryItem(
      id: 'inventory-id',
      name: 'Kopi',
      stock: 1200,
      unit: ProductUnit(id: 'portion-id', name: 'Porsi', abbreviation: 'porsi'),
      isActive: true,
      buyPrice: 2,
    ),
  ];

  @override
  Future<List<ProductUnit>> getProductUnits() async => const [
    ProductUnit(id: 'portion-id', name: 'Porsi', abbreviation: 'porsi'),
  ];

  @override
  Future<void> addRecipe({
    required String productId,
    required String inventoryId,
    required num quantity,
    required String unitId,
    required num conversionFactor,
  }) async {
    addedInventoryId = inventoryId;
    addedQuantity = quantity;
    addedUnitId = unitId;
    addedConversionFactor = conversionFactor;
  }
}

class _ProductDialogTestRepository extends _FakeProductManagementRepository {
  _ProductDialogTestRepository({this.withExistingProduct = false});

  final bool withExistingProduct;
  String? savedName;
  String? savedProductId;
  num? savedPrice;
  num? savedStock;

  @override
  Future<List<ManagedCategory>> getCategories() async => const [
    ManagedCategory(
      id: 'category-id',
      name: 'Minuman',
      description: '',
      isActive: true,
    ),
  ];

  @override
  Future<List<ManagedProduct>> getProducts() async => withExistingProduct
      ? [
          ManagedProduct(
            product: const CatalogProduct(
              id: 'existing-product-id',
              name: 'Cappuccino',
              price: 24000,
              stock: 30,
              imageUrl: '',
              isActive: true,
              category: ProductCategory(
                id: 'category-id',
                name: 'Minuman',
                isActive: true,
              ),
              variantGroups: [],
            ),
            variantGroupIds: [],
          ),
        ]
      : const [];

  @override
  Future<ManagedProduct> saveProduct({
    String? productId,
    required String name,
    required num price,
    required num stock,
    required String categoryId,
    required List<String> variantGroupIds,
    required List<ProductImage> images,
    required bool isActive,
  }) async {
    savedProductId = productId;
    savedName = name;
    savedPrice = price;
    savedStock = stock;
    return super.saveProduct(
      productId: productId,
      name: name,
      price: price,
      stock: stock,
      categoryId: categoryId,
      variantGroupIds: variantGroupIds,
      images: images,
      isActive: isActive,
    );
  }
}

class _FakeVariantGroupsRepository implements VariantGroupsRepository {
  final List<VariantGroupDefinition> variantGroupDefinitions = [];

  @override
  Future<List<VariantGroupDefinition>> getVariantGroupDefinitions() async =>
      List.unmodifiable(variantGroupDefinitions);

  @override
  Future<VariantRecipeReferences> getVariantRecipeReferences() async =>
      const VariantRecipeReferences(inventories: [], units: []);

  @override
  Future<VariantGroupDefinition> saveVariantGroup({
    String? groupId,
    required String name,
    required bool isRequired,
    required int minSelection,
    required int maxSelection,
    required List<VariantOptionDefinition> options,
  }) async {
    final definition = VariantGroupDefinition(
      id: groupId ?? 'group-id',
      name: name,
      isRequired: isRequired,
      minSelection: minSelection,
      maxSelection: maxSelection,
      options: options,
    );
    variantGroupDefinitions.removeWhere((group) => group.id == definition.id);
    variantGroupDefinitions.add(definition);
    return definition;
  }

  @override
  Future<void> deleteVariantGroup(String groupId) async {
    variantGroupDefinitions.removeWhere((group) => group.id == groupId);
  }
}

class _VariantGroupsReferencesUnavailableRepository
    extends _FakeVariantGroupsRepository {
  @override
  Future<List<VariantGroupDefinition>> getVariantGroupDefinitions() async => [
    const VariantGroupDefinition(
      id: 'group-id',
      name: 'Ukuran',
      isRequired: true,
      minSelection: 1,
      maxSelection: 1,
      options: [
        VariantOptionDefinition(
          name: 'Large',
          priceAdjustment: 5000,
          recipes: [],
        ),
      ],
    ),
  ];

  @override
  Future<VariantRecipeReferences> getVariantRecipeReferences() {
    throw Exception('GET /api/inventories: Unauthorized');
  }
}

class _FakeCategoriesRepository implements CategoriesRepository {
  ManagedCategory? savedCategory;

  @override
  Future<List<ManagedCategory>> getCategories() async => [?savedCategory];

  @override
  Future<ManagedCategory> saveCategory({
    String? categoryId,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    savedCategory = ManagedCategory(
      id: categoryId ?? 'category-id',
      name: name,
      description: description,
      isActive: isActive,
    );
    return savedCategory!;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    savedCategory = null;
  }
}
