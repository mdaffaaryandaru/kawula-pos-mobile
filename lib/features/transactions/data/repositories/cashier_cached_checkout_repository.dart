import 'dart:convert';

import 'package:kawula_pos/features/members/data/models/member_model.dart';
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/members/domain/entities/member_reward_claim.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/transactions/data/models/checkout_models.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/run_with_network_cache.dart';

class CashierCachedCheckoutRepository implements CheckoutRepository {
  const CashierCachedCheckoutRepository(this._delegate, this._cache);

  final CheckoutRepository _delegate;
  final CashierMasterDataCache _cache;

  @override
  Future<List<CheckoutPaymentMethod>> getPaymentMethods() =>
      runWithNetworkCache(
        request: () async {
          final methods = await _delegate.getPaymentMethods();
          await _cache.save(
            cacheType: 'checkout_payment_methods',
            dataKey: 'active',
            payload: methods
                .map(CheckoutPaymentMethodModel.fromEntity)
                .map((method) => method.toJson())
                .toList(growable: false),
          );
          return methods;
        },
        readCache: () async {
          final cached = await _cache.read(
            cacheType: 'checkout_payment_methods',
            dataKey: 'active',
          );
          if (cached == null) return null;
          final decoded = jsonDecode(jsonEncode(cached));
          if (decoded is! List) {
            throw const FormatException('Cache metode pembayaran tidak valid.');
          }
          return decoded
              .map((item) {
                if (item is! Map<String, dynamic>) {
                  throw const FormatException(
                    'Data metode pembayaran pada cache tidak valid.',
                  );
                }
                return CheckoutPaymentMethodModel.fromJson(item);
              })
              .toList(growable: false);
        },
        skipRequest: _cache.shouldUseOfflineData,
        onNetworkFailure: _cache.markOffline,
        onRequestSuccess: _cache.markOnline,
      );

  @override
  Future<CheckoutSettings> getSettings() => runWithNetworkCache(
    request: () async {
      final settings = await _delegate.getSettings();
      await _cache.save(
        cacheType: 'checkout_settings',
        dataKey: 'store',
        payload: CheckoutSettingsModel.fromEntity(settings).toJson(),
      );
      return settings;
    },
    readCache: () async {
      final cached = await _cache.read(
        cacheType: 'checkout_settings',
        dataKey: 'store',
      );
      if (cached == null) return null;
      final decoded = jsonDecode(jsonEncode(cached));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Cache pengaturan checkout tidak valid.');
      }
      return CheckoutSettingsModel.fromJson(decoded);
    },
    skipRequest: _cache.shouldUseOfflineData,
    onNetworkFailure: _cache.markOffline,
    onRequestSuccess: _cache.markOnline,
  );

  @override
  Future<List<Member>> searchMembers(String search) => runWithNetworkCache(
    request: () async {
      final members = await _delegate.searchMembers(search);
      await _cache.save(
        cacheType: 'checkout_member_search',
        dataKey: search,
        payload: members
            .map(MemberModel.fromEntity)
            .map((member) => member.toJson())
            .toList(growable: false),
      );
      return members;
    },
    readCache: () async {
      final cached = await _cache.read(
        cacheType: 'checkout_member_search',
        dataKey: search,
      );
      if (cached == null) return null;
      final decoded = jsonDecode(jsonEncode(cached));
      if (decoded is! List) {
        throw const FormatException('Cache pencarian member tidak valid.');
      }
      return decoded
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Data member pada cache tidak valid.',
              );
            }
            return MemberModel.fromJson(item);
          })
          .toList(growable: false);
    },
    skipRequest: _cache.shouldUseOfflineData,
    onNetworkFailure: _cache.markOffline,
    onRequestSuccess: _cache.markOnline,
  );

  @override
  Future<List<TransactionRecord>> getTransactions() =>
      _delegate.getTransactions();

  @override
  Future<TransactionRecord> getTransaction(String transactionId) =>
      _delegate.getTransaction(transactionId);

  @override
  Future<TransactionRecord> cancelTransaction({
    required String transactionId,
    required String reason,
  }) =>
      _delegate.cancelTransaction(transactionId: transactionId, reason: reason);

  @override
  Future<TransactionRecord> refundTransaction({
    required String transactionId,
    required String pin,
    required String reason,
  }) => _delegate.refundTransaction(
    transactionId: transactionId,
    pin: pin,
    reason: reason,
  );

  @override
  Future<MemberRewardClaim> claimMemberReward(String memberId) =>
      _delegate.claimMemberReward(memberId);

  @override
  Future<CheckoutResult> payPendingTransaction({
    required String transactionId,
    required String paymentMethod,
    required num paidAmount,
    required String pin,
  }) => _delegate.payPendingTransaction(
    transactionId: transactionId,
    paymentMethod: paymentMethod,
    paidAmount: paidAmount,
    pin: pin,
  );

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
  }) => _delegate.createTransaction(
    outletId: outletId,
    items: items,
    estimatedTotal: estimatedTotal,
    serviceCharge: serviceCharge,
    paymentMethod: paymentMethod,
    paidAmount: paidAmount,
    pin: pin,
    openBill: openBill,
    memberId: memberId,
    tableNumber: tableNumber,
  );
}
