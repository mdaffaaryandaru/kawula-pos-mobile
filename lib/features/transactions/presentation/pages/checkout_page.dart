// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/members/domain/entities/member.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_cubit.dart';
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_state.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/checkout_form_widgets.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/checkout_receipt_widgets.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/checkout_state_widgets.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.outletId,
    this.onTransactionSuccess,
  });

  final String? outletId;
  final VoidCallback? onTransactionSuccess;

  @override
  State<CheckoutPage> createState() => CheckoutPageState();
}

class CheckoutPageState extends State<CheckoutPage> {
  final cashController = TextEditingController();
  final pinController = TextEditingController();
  final memberSearchController = TextEditingController();
  final tableNumberController = TextEditingController();
  final memberSearchFocusNode = FocusNode();
  Timer? memberSearchTimer;
  List<Member> memberResults = const [];
  Member? selectedMember;
  bool isSearchingMembers = false;
  bool isClaimingReward = false;
  String? memberSearchError;
  int memberSearchGeneration = 0;
  String? selectedMethodCode;
  bool serviceChargeEnabled = true;
  bool openBill = false;
  String? validationMessage;

  void updateState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void dispose() {
    cashController.dispose();
    pinController.dispose();
    memberSearchTimer?.cancel();
    memberSearchController.dispose();
    tableNumberController.dispose();
    memberSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutCompleted) {
          context.read<CartCubit>().clear();
          widget.onTransactionSuccess?.call();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Pembayaran'),
              ],
            ),
          ),
          body: switch (state) {
            CheckoutLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            CheckoutFailure() => failure(context, state.message),
            CheckoutCompleted() => completed(state.result, state.settings),
            CheckoutReady() => checkoutForm(
              context,
              state.paymentMethods,
              state.settings,
              isSubmitting: false,
              errorMessage: state.errorMessage,
            ),
            CheckoutSubmitting() => checkoutForm(
              context,
              state.paymentMethods,
              state.settings,
              isSubmitting: true,
            ),
          },
        );
      },
    );
  }
}
