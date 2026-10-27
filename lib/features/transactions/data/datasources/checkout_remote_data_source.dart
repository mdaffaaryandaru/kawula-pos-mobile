import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../framework/core/exceptions/api_exception.dart';
import '../../../products/presentation/bloc/cart_cubit.dart';
import '../models/checkout_models.dart';

class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource(this._client, this._baseUrl, this._readToken);

  final http.Client _client;
  final String _baseUrl;
  final Future<String?> Function() _readToken;

  Future<List<CheckoutPaymentMethodModel>> getPaymentMethods() async {
    final response = await _client.get(
      _uri('payment-methods'),
      headers: await _authorizedHeaders(),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw const ApiException('Respons metode pembayaran tidak valid.');
    }
    final methods = <CheckoutPaymentMethodModel>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) {
        throw const ApiException('Data metode pembayaran tidak valid.');
      }
      if (item['is_active'] == false) continue;
      methods.add(CheckoutPaymentMethodModel.fromJson(item));
    }
    return methods;
  }

  Future<CheckoutSettingsModel> getSettings() async {
    final response = await _client.get(
      _uri('store-settings'),
      headers: await _authorizedHeaders(),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons pengaturan toko tidak valid.');
    }
    return CheckoutSettingsModel.fromJson(decoded);
  }

  Future<List<TransactionRecordModel>> getTransactions() async {
    final response = await _client.get(
      _uri('transactions'),
      headers: await _authorizedHeaders(),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! List) {
      throw const ApiException('Respons riwayat transaksi tidak valid.');
    }
    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException(
              'Data transaksi pada riwayat tidak valid.',
            );
          }
          return TransactionRecordModel.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<CheckoutResultModel> payPendingTransaction({
    required String transactionId,
    required String paymentMethod,
    required num paidAmount,
    required String pin,
  }) async {
    final response = await _client.patch(
      _uri('transactions/$transactionId/pay'),
      headers: await _authorizedHeaders(),
      body: jsonEncode({
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
        'pin': pin,
      }),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons pelunasan transaksi tidak valid.');
    }
    return CheckoutResultModel.fromJson(decoded);
  }

  Future<CheckoutResultModel> createTransaction({
    required String outletId,
    required List<CartItem> items,
    required num estimatedTotal,
    required String paymentMethod,
    required num paidAmount,
    required String? pin,
    required bool openBill,
  }) async {
    final body = <String, Object>{
      'outlet_id': outletId,
      'items': items
          .map(
            (item) => {
              'product_id': item.product.id,
              'quantity': item.quantity,
              'selected_variants': item.selectedVariants
                  .map(
                    (variant) => {
                      'group_name': variant.groupName,
                      'option_name': variant.optionName,
                      if (variant.optionId != null)
                        'option_id': variant.optionId!,
                    },
                  )
                  .toList(),
              if (item.notes.trim().isNotEmpty) 'notes': item.notes.trim(),
            },
          )
          .toList(),
      'total_amount': estimatedTotal.round(),
      'payment_method': openBill ? 'OPEN_BILL' : paymentMethod,
      if (openBill) 'status': 'pending',
      if (!openBill) 'paid_amount': paidAmount,
      if (!openBill && pin != null) 'pin': pin,
    };
    final response = await _client.post(
      _uri('transactions'),
      headers: await _authorizedHeaders(),
      body: jsonEncode(body),
    );
    final decoded = _decodeResponse(response);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Respons transaksi tidak valid.');
    }
    return CheckoutResultModel.fromJson(decoded);
  }

  Uri _uri(String path) {
    final baseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return Uri.parse('$baseUrl/$path');
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sesi login tidak ditemukan. Silakan masuk lagi.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Object? _decodeResponse(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Permintaan gagal dengan kode ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      throw const ApiException('Respons server tidak valid.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']
          : null;
      final errorMessage = message is String
          ? message
          : message is List
          ? message.whereType<String>().join('\n')
          : null;
      throw ApiException(
        errorMessage?.isNotEmpty == true
            ? errorMessage!
            : 'Permintaan gagal dengan kode ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}
