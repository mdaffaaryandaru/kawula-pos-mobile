import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../products/presentation/bloc/cart_cubit.dart';
import '../../../products/presentation/pages/product_formatters.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/checkout.dart';
import '../bloc/checkout_cubit.dart';
import '../bloc/checkout_state.dart';

part '../widgets/checkout_form_widgets.dart';
part '../widgets/checkout_receipt_actions.dart';
part '../widgets/checkout_member_widgets.dart';
part '../widgets/checkout_state_widgets.dart';
part '../widgets/checkout_receipt_widgets.dart';
part '../widgets/checkout_shared_widgets.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.outletId});

  final String? outletId;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _cashController = TextEditingController();
  final _pinController = TextEditingController();
  final _memberSearchController = TextEditingController();
  final _tableNumberController = TextEditingController();
  final _memberSearchFocusNode = FocusNode();
  Timer? _memberSearchTimer;
  List<Member> _memberResults = const [];
  Member? _selectedMember;
  bool _isSearchingMembers = false;
  String? _memberSearchError;
  int _memberSearchGeneration = 0;
  String? _selectedMethodCode;
  bool _openBill = false;
  String? _validationMessage;

  @override
  void dispose() {
    _cashController.dispose();
    _pinController.dispose();
    _memberSearchTimer?.cancel();
    _memberSearchController.dispose();
    _tableNumberController.dispose();
    _memberSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutCompleted) {
          context.read<CartCubit>().clear();
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
            CheckoutFailure() => _failure(context, state.message),
            CheckoutCompleted() => _completed(state.result, state.settings),
            CheckoutReady() => _checkoutForm(
              context,
              state.paymentMethods,
              state.settings,
              isSubmitting: false,
              errorMessage: state.errorMessage,
            ),
            CheckoutSubmitting() => _checkoutForm(
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
