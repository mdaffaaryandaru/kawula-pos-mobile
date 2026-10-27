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
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/products/domain/entities/product_management.dart';
import 'package:kawula_pos/features/categories/domain/entities/managed_category.dart';
import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/product_management_repository.dart';
import 'package:kawula_pos/features/balances/domain/entities/balance.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/shifts/domain/entities/admin_shift_detail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kawula_pos/main.dart';

void main() {
  testWidgets('routes admin to dashboard and exposes admin features', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository(role: 'Admin');
    final shiftsRepository = _FakeShiftsRepository();
    final userManagementRepository = _FakeUserManagementRepository();
    final categoriesRepository = _FakeCategoriesRepository();

    await tester.pumpWidget(
      KawulaPosApp(
        authRepository: authRepository,
        shiftsRepository: shiftsRepository,
        catalogRepository: _FakeCatalogRepository(),
        checkoutRepository: _FakeCheckoutRepository(),
        balancesRepository: _FakeBalancesRepository(),
        userManagementRepository: userManagementRepository,
        productManagementRepository: _FakeProductManagementRepository(),
        categoriesRepository: categoriesRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'admin@kawula.id');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Produk'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Pengaturan kasir'), findsOneWidget);
    expect(find.text('Keuangan'), findsOneWidget);
    expect(find.text('Shift kasir'), findsOneWidget);
    expect(shiftsRepository.activeChecks, 0);

    await tester.tap(find.text('Keuangan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada saldo tercatat.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

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
        authRepository: repository,
        shiftsRepository: shiftsRepository,
        catalogRepository: catalogRepository,
        checkoutRepository: checkoutRepository,
        balancesRepository: _FakeBalancesRepository(),
        userManagementRepository: _FakeUserManagementRepository(),
        productManagementRepository: _FakeProductManagementRepository(),
        categoriesRepository: _FakeCategoriesRepository(),
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
    expect(find.textContaining('Kopi Susu'), findsOneWidget);
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
    await tester.tap(find.byType(DropdownButtonFormField<String>));
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
    await tester.drag(find.byType(ListView), const Offset(0, -600));
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
    expect(find.text('Pembayaran berhasil'), findsOneWidget);
    expect(find.text('STRUK PEMBAYARAN'), findsOneWidget);
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
    expect(find.textContaining('Lunas ·'), findsOneWidget);
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

class _FakeBalancesRepository implements BalancesRepository {
  @override
  Future<List<BalanceAccount>> getBalances() async => [];

  @override
  Future<List<BalanceHistoryEntry>> getHistory() async => [];

  @override
  Future<void> recordExpense({
    required String paymentMethod,
    required num amount,
    required String notes,
  }) async {}

  @override
  Future<void> adjustBalance({
    required String paymentMethod,
    required num actualBalance,
    required String notes,
  }) async {}
}

class _FakeCheckoutRepository implements CheckoutRepository {
  String? submittedOutletId;
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
  }) async {
    submittedOutletId = outletId;
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
