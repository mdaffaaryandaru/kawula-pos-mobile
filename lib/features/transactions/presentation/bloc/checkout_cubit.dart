// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/members/domain/entities/member_reward_claim.dart';
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart'
    show CheckoutModeProvider, CheckoutRepository;
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._repository) : super(const CheckoutLoading());

  final CheckoutRepository _repository;
  bool _isSubmitting = false;

  bool get isOffline => switch (_repository) {
    CheckoutModeProvider provider => provider.isOffline,
    _ => false,
  };

  Future<List<Member>> searchMembers(String search) =>
      _repository.searchMembers(search);

  Future<MemberRewardClaim> claimMemberReward(String memberId) =>
      _repository.claimMemberReward(memberId);

  Future<void> load() async {
    emit(const CheckoutLoading());
    try {
      final methods = await _repository.getPaymentMethods();
      final settings = await _repository.getSettings();
      emit(
        CheckoutReady(
          paymentMethods: methods,
          settings: settings,
          isOffline: isOffline,
        ),
      );
    } catch (error) {
      emit(CheckoutFailure(_messageFor(error)));
    }
  }

  Future<void> submit({
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
    if (_isSubmitting) return;
    final currentState = state;
    if (currentState is! CheckoutReady) return;
    if (items.isEmpty) {
      emit(
        CheckoutReady(
          paymentMethods: currentState.paymentMethods,
          settings: currentState.settings,
          errorMessage: 'Keranjang masih kosong.',
        ),
      );
      return;
    }

    final stockIssues = CartState(items).stockIssues;
    if (stockIssues.isNotEmpty) {
      emit(
        CheckoutReady(
          paymentMethods: currentState.paymentMethods,
          settings: currentState.settings,
          errorMessage: stockIssues.map((issue) => issue.message).join('\n'),
        ),
      );
      return;
    }

    emit(
      CheckoutSubmitting(
        paymentMethods: currentState.paymentMethods,
        settings: currentState.settings,
        isOffline: isOffline,
      ),
    );
    _isSubmitting = true;
    try {
      final result = await _repository.createTransaction(
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
      emit(CheckoutCompleted(result, currentState.settings));
    } catch (error) {
      emit(
        CheckoutReady(
          paymentMethods: currentState.paymentMethods,
          settings: currentState.settings,
          isOffline: isOffline,
          errorMessage: _messageFor(error),
        ),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) return error.message;
    return error.toString();
  }
}
