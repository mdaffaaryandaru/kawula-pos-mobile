import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawula_pos/features/payment_method/domain/entities/payment_method.dart';
import 'package:kawula_pos/features/payment_method/domain/repositories/payment_methods_repository.dart';
import 'package:kawula_pos/features/payment_method/presentation/pages/payment_methods_management_page.dart';

void main() {
  testWidgets('lists and searches payment methods and protects CASH', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentMethodsManagementPage(
          repository: _FakePaymentMethodsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Metode Pembayaran'), findsNWidgets(2));
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('QRIS'), findsNWidgets(2));
    expect(find.text('CASH'), findsOneWidget);
    expect(find.text('BANK_TRANSFER'), findsOneWidget);
    expect(
      find.byTooltip('Metode CASH bawaan sistem tidak dapat dihapus'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, 'bank_transfer');
    await tester.pumpAndSettle();
    expect(find.text('Transfer Bank'), findsOneWidget);
    expect(find.text('Cash'), findsNothing);
  });

  testWidgets('creates a method with uppercase code', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakePaymentMethodsRepository(methods: []);

    await tester.pumpWidget(
      MaterialApp(home: PaymentMethodsManagementPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah Metode Pembayaran').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Kartu');
    await tester.enterText(find.byType(TextFormField).at(1), 'card');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Pembayaran kartu',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(repository.methods.single.code, 'CARD');
    expect(repository.methods.single.name, 'Kartu');
  });

  testWidgets('keeps the payment method code unchanged when editing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakePaymentMethodsRepository();

    await tester.pumpWidget(
      MaterialApp(home: PaymentMethodsManagementPage(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit').at(1));
    await tester.pumpAndSettle();

    final codeField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Kode'),
    );
    expect(codeField.enabled, isFalse);
    await tester.enterText(find.byType(TextFormField).first, 'QRIS Bisnis');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      'QRIS Bisnis',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final qris = repository.methods.singleWhere(
      (method) => method.id == 'qris-id',
    );
    expect(qris.name, 'QRIS Bisnis');
    expect(qris.code, 'QRIS');
  });
}

class _FakePaymentMethodsRepository implements PaymentMethodsRepository {
  _FakePaymentMethodsRepository({List<PaymentMethod>? methods})
    : methods =
          methods ??
          <PaymentMethod>[
            PaymentMethod(
              id: 'cash-id',
              name: 'Cash',
              code: 'CASH',
              description: 'Pembayaran tunai langsung di kasir',
              isActive: true,
            ),
            PaymentMethod(
              id: 'qris-id',
              name: 'QRIS',
              code: 'QRIS',
              description: 'Ini Pembayaran QRIS',
              isActive: true,
            ),
            PaymentMethod(
              id: 'bank-id',
              name: 'Transfer Bank',
              code: 'BANK_TRANSFER',
              description: 'Pembayaran melalui transfer bank',
              isActive: true,
            ),
          ];

  final List<PaymentMethod> methods;
  var _nextId = 0;

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async =>
      List.unmodifiable(methods);

  @override
  Future<PaymentMethod> getPaymentMethod(String paymentMethodId) async =>
      methods.firstWhere((method) => method.id == paymentMethodId);

  @override
  Future<PaymentMethod> savePaymentMethod({
    String? paymentMethodId,
    required String? code,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    final existing = paymentMethodId == null
        ? null
        : methods.firstWhere((method) => method.id == paymentMethodId);
    final saved = PaymentMethod(
      id: paymentMethodId ?? 'new-${_nextId++}',
      name: name,
      code: existing?.code ?? code!.toUpperCase(),
      description: description,
      isActive: isActive,
    );
    methods.removeWhere((method) => method.id == saved.id);
    methods.add(saved);
    return saved;
  }

  @override
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    methods.removeWhere((method) => method.id == paymentMethodId);
  }
}
