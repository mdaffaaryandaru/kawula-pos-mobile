import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kawula_pos/features/products/domain/entities/catalog_product.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/transactions/data/datasources/checkout_remote_data_source.dart';
import 'package:kawula_pos/features/members/data/datasources/members_remote_data_source.dart';

CheckoutRemoteDataSource _checkoutDataSource(
  http.Client client,
  String baseUrl,
) {
  Future<String?> readToken() async => 'jwt-token';
  return CheckoutRemoteDataSource(
    client,
    baseUrl,
    readToken,
    membersRemoteDataSource: MembersRemoteDataSource(
      client,
      baseUrl,
      readToken,
    ),
  );
}

void main() {
  const baseUrl = 'http://localhost:3001/api';

  test('loads active payment methods and store checkout settings', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/payment-methods')) {
        return http.Response(
          jsonEncode([
            {'name': 'Tunai', 'code': 'CASH', 'is_active': true},
            {'name': 'QRIS', 'code': 'QRIS', 'is_active': true},
            {'name': 'Transfer Lama', 'code': 'BANK', 'is_active': false},
          ]),
          200,
        );
      }
      expect(request.url, Uri.parse('$baseUrl/store-settings'));
      return http.Response(
        jsonEncode({
          'store_name': 'Kawula Store',
          'address': 'Jl. Kasir 1',
          'logo_url': '/uploads/store/logo.png',
          'tax_percentage': 10,
          'service_charge': 2500,
        }),
        200,
      );
    });
    final dataSource = _checkoutDataSource(client, baseUrl);

    final methods = await dataSource.getPaymentMethods();
    final settings = await dataSource.getSettings();

    expect(methods.map((method) => method.code), ['CASH', 'QRIS']);
    expect(settings.taxPercentage, 10);
    expect(settings.serviceCharge, 2500);
    expect(settings.storeName, 'Kawula Store');
    expect(settings.address, 'Jl. Kasir 1');
    expect(settings.logoUrl, '/uploads/store/logo.png');
  });

  test(
    'sends completed transactions using the backend payload contract',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url, Uri.parse('$baseUrl/transactions'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['outlet_id'], 'outlet-id');
        expect(body['total_amount'], 19800);
        expect(body['payment_method'], 'CASH');
        expect(body['paid_amount'], 20000);
        expect(body['pin'], '1234');
        expect(body['member_id'], 'member-id');
        expect(body['table_number'], 'A1');
        expect(body.containsKey('status'), isFalse);
        final item = (body['items'] as List).single as Map<String, dynamic>;
        expect(item['product_id'], 'product-id');
        expect(item['quantity'], 2);
        expect(item['notes'], 'tanpa gula');
        expect(item['selected_variants'], [
          {
            'group_name': 'Ukuran',
            'option_name': 'Besar',
            'option_id': 'option-id',
          },
        ]);
        return http.Response(
          jsonEncode({
            '_id': 'transaction-id',
            'status': 'completed',
            'total_amount': 19800,
            'subtotal': 18000,
            'tax_amount': 1800,
            'service_charge': 0,
            'discount_amount': 0,
            'payment_method': 'CASH',
            'paid_amount': 20000,
            'change_amount': 200,
            'createdAt': '2026-10-27T09:00:00.000Z',
            'items': [
              {
                'product_id': {'_id': 'product-id', 'name': 'Kopi Susu'},
                'quantity': 1,
                'price': 18000,
                'selected_variants': [
                  {
                    'group_name': 'Ukuran',
                    'option_name': 'Besar',
                    'price_adjustment': 0,
                  },
                ],
                'notes': 'panas',
              },
            ],
          }),
          201,
        );
      });
      final dataSource = _checkoutDataSource(client, baseUrl);

      final result = await dataSource.createTransaction(
        outletId: 'outlet-id',
        items: [
          CartItem(
            product: const CatalogProduct(
              id: 'product-id',
              name: 'Kopi Susu',
              price: 18000,
              imageUrl: '',
              isActive: true,
              category: null,
              variantGroups: [],
            ),
            quantity: 2,
            selectedVariants: const [
              SelectedProductVariant(
                groupName: 'Ukuran',
                optionName: 'Besar',
                optionId: 'option-id',
                priceAdjustment: 5000,
              ),
            ],
            notes: 'tanpa gula',
          ),
        ],
        estimatedTotal: 19800,
        paymentMethod: 'CASH',
        paidAmount: 20000,
        pin: '1234',
        openBill: false,
        memberId: 'member-id',
        tableNumber: ' A1 ',
      );

      expect(result.id, 'transaction-id');
      expect(result.status, 'completed');
      expect(result.totalAmount, 19800);
      expect(result.changeAmount, 200);
      expect(result.subtotal, 18000);
      expect(result.taxAmount, 1800);
      expect(result.items.single.productName, 'Kopi Susu');
      expect(result.items.single.selectedVariants.single.optionName, 'Besar');
      expect(result.items.single.notes, 'panas');
    },
  );

  test(
    'sends open bills as pending without payment PIN or paid amount',
    () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['payment_method'], 'OPEN_BILL');
        expect(body['status'], 'pending');
        expect(body.containsKey('paid_amount'), isFalse);
        expect(body.containsKey('pin'), isFalse);
        expect(body.containsKey('member_id'), isFalse);
        expect(body['table_number'], '12');
        return http.Response(
          jsonEncode({
            '_id': 'pending-transaction',
            'status': 'pending',
            'total_amount': 19800,
            'payment_method': 'OPEN_BILL',
            'paid_amount': 0,
            'change_amount': 0,
          }),
          201,
        );
      });
      final dataSource = _checkoutDataSource(client, baseUrl);

      final result = await dataSource.createTransaction(
        outletId: 'outlet-id',
        items: [
          CartItem(
            product: const CatalogProduct(
              id: 'product-id',
              name: 'Kopi Susu',
              price: 18000,
              imageUrl: '',
              isActive: true,
              category: null,
              variantGroups: [],
            ),
            quantity: 1,
            selectedVariants: const [],
          ),
        ],
        estimatedTotal: 19800,
        paymentMethod: 'CASH',
        paidAmount: 0,
        pin: null,
        openBill: true,
        tableNumber: ' 12 ',
      );

      expect(result.status, 'pending');
      expect(result.paymentMethod, 'OPEN_BILL');
    },
  );

  test('searches members using the existing authenticated endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/members');
      expect(request.url.queryParameters['search'], '0812 3456');
      expect(request.headers['Authorization'], 'Bearer jwt-token');
      return http.Response(
        jsonEncode([
          {
            '_id': 'member-id',
            'name': 'Siti Member',
            'phone_number': '08123456',
            'current_stamps': 2,
            'is_active': true,
          },
          {
            '_id': 'inactive-member-id',
            'name': 'Member Nonaktif',
            'phone_number': '08100000',
            'current_stamps': 0,
            'is_active': false,
          },
        ]),
        200,
      );
    });
    final dataSource = _checkoutDataSource(client, baseUrl);

    final members = await dataSource.searchMembers('0812 3456');

    expect(members, hasLength(2));
    expect(members.first.id, 'member-id');
    expect(members.first.currentStamps, 2);
    expect(members.last.isActive, isFalse);
  });

  test(
    'lists transactions and settles pending bills using the existing API',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url, Uri.parse('$baseUrl/transactions'));
          return http.Response(
            jsonEncode([
              {
                '_id': 'pending-id',
                'status': 'pending',
                'total_amount': 25000,
                'payment_method': 'OPEN_BILL',
                'paid_amount': 0,
                'change_amount': 0,
                'subtotal': 23000,
                'tax_amount': 2000,
                'service_charge': 500,
                'discount_amount': 500,
                'cogs': 8000,
                'refund_amount': 0,
                'outlet_id': {
                  '_id': 'outlet-id',
                  'name': 'Kawula Cafe Main',
                  'code': 'MAIN',
                },
                'created_by': {
                  '_id': 'cashier-id',
                  'name': 'Admin Kawula',
                  'email': 'admin@example.test',
                },
                'member_id': {
                  '_id': 'member-id',
                  'name': 'Siti Member',
                  'phone_number': '08123456789',
                },
                'createdAt': '2026-10-27T09:00:00.000Z',
                'items': [
                  {
                    'product_id': {'_id': 'product-id', 'name': 'Kopi Susu'},
                    'quantity': 1,
                    'price': 25000,
                    'notes': 'panas',
                  },
                ],
              },
            ]),
            200,
          );
        }

        expect(request.method, 'PATCH');
        expect(request.url, Uri.parse('$baseUrl/transactions/pending-id/pay'));
        expect(jsonDecode(request.body), {
          'payment_method': 'CASH',
          'paid_amount': 30000,
          'pin': '1234',
        });
        return http.Response(
          jsonEncode({
            '_id': 'pending-id',
            'status': 'completed',
            'total_amount': 25000,
            'payment_method': 'CASH',
            'paid_amount': 30000,
            'change_amount': 5000,
          }),
          200,
        );
      });
      final dataSource = _checkoutDataSource(client, baseUrl);

      final transactions = await dataSource.getTransactions();
      expect(transactions, hasLength(1));
      expect(transactions.single.isPending, isTrue);
      expect(transactions.single.items.single.productName, 'Kopi Susu');
      expect(transactions.single.items.single.notes, 'panas');
      expect(transactions.single.subtotal, 23000);
      expect(transactions.single.taxAmount, 2000);
      expect(transactions.single.serviceCharge, 500);
      expect(transactions.single.discountAmount, 500);
      expect(transactions.single.cogs, 8000);
      expect(transactions.single.outletName, 'Kawula Cafe Main');
      expect(transactions.single.cashierName, 'Admin Kawula');
      expect(transactions.single.memberName, 'Siti Member');

      final result = await dataSource.payPendingTransaction(
        transactionId: 'pending-id',
        paymentMethod: 'CASH',
        paidAmount: 30000,
        pin: '1234',
      );
      expect(result.status, 'completed');
      expect(result.changeAmount, 5000);
    },
  );

  test('loads transaction details and uses the existing cancel and refund endpoints', () async {
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (request.method == 'GET') {
        expect(request.url, Uri.parse('$baseUrl/transactions/transaction-id'));
        return http.Response(jsonEncode(_transactionDetailJson()), 200);
      }
      if (request.method == 'PATCH') {
        expect(
          request.url,
          Uri.parse('$baseUrl/transactions/transaction-id/cancel'),
        );
        expect(jsonDecode(request.body), {'reason': 'Salah input'});
        return http.Response(
          jsonEncode(
            _transactionDetailJson(
              status: 'cancelled',
              refundReason: 'Salah input',
            ),
          ),
          200,
        );
      }
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse('$baseUrl/transactions/transaction-id/refund'),
      );
      expect(jsonDecode(request.body), {
        'pin': '1234',
        'reason': 'Pesanan salah',
      });
      return http.Response(
        jsonEncode(
          _transactionDetailJson(
            status: 'refunded',
            refundReason: 'Pesanan salah',
            refundAmount: 25000,
          ),
        ),
        201,
      );
    });
    final dataSource = _checkoutDataSource(client, baseUrl);

    final detail = await dataSource.getTransaction('transaction-id');
    final cancelled = await dataSource.cancelTransaction(
      transactionId: 'transaction-id',
      reason: 'Salah input',
    );
    final refunded = await dataSource.refundTransaction(
      transactionId: 'transaction-id',
      pin: '1234',
      reason: 'Pesanan salah',
    );

    expect(detail.tableNumber, 'A1');
    expect(detail.memberName, 'Siti Member');
    expect(detail.items.single.selectedVariants.single.optionName, 'Besar');
    expect(cancelled.status, 'cancelled');
    expect(cancelled.refundReason, 'Salah input');
    expect(refunded.status, 'refunded');
    expect(refunded.refundAmount, 25000);
    expect(requests, [
      'GET /api/transactions/transaction-id',
      'PATCH /api/transactions/transaction-id/cancel',
      'POST /api/transactions/transaction-id/refund',
    ]);
  });
}

Map<String, Object?> _transactionDetailJson({
  String status = 'completed',
  String refundReason = '',
  num refundAmount = 0,
}) => {
  '_id': 'transaction-id',
  'status': status,
  'total_amount': 25000,
  'subtotal': 23000,
  'tax_amount': 2000,
  'service_charge': 500,
  'discount_amount': 500,
  'payment_method': 'QRIS',
  'paid_amount': 25000,
  'change_amount': 0,
  'table_number': 'A1',
  'refund_amount': refundAmount,
  'refund_reason': refundReason,
  'member_id': {'_id': 'member-id', 'name': 'Siti Member'},
  'items': [
    {
      'product_id': {'_id': 'product-id', 'name': 'Kopi Susu'},
      'quantity': 1,
      'price': 25000,
      'selected_variants': [
        {'group_name': 'Ukuran', 'option_name': 'Besar'},
      ],
      'notes': 'panas',
    },
  ],
};
