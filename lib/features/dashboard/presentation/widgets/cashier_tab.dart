import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../../products/presentation/bloc/cart_cubit.dart';
import '../../../products/presentation/bloc/catalog_cubit.dart';
import '../../../products/presentation/pages/catalog_page.dart';
import '../../../shifts/presentation/bloc/shifts_cubit.dart';
import '../../../shifts/presentation/bloc/shifts_state.dart';
import '../../../shifts/presentation/pages/shift_status_view.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';

class CashierTab extends StatelessWidget {
  const CashierTab({
    super.key,
    required this.admin,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.onManageShift,
  });

  final AuthUser admin;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final VoidCallback onManageShift;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftsCubit, ShiftsState>(
      builder: (context, state) => switch (state) {
        ShiftsLoading() => const Scaffold(
          appBar: CashierAppBar(),
          body: Center(child: CircularProgressIndicator()),
        ),
        ShiftsNeedsOpening() => Scaffold(
          appBar: const CashierAppBar(),
          body: ShiftStatusView(
            user: admin,
            cashAvailability: state.cashAvailability,
            errorMessage: state.errorMessage,
          ),
        ),
        ShiftsOpening() => Scaffold(
          appBar: const CashierAppBar(),
          body: ShiftStatusView(
            user: admin,
            cashAvailability: state.cashAvailability,
            isOpening: true,
          ),
        ),
        ShiftsActive() => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => CatalogCubit(catalogRepository)..load(),
            ),
            BlocProvider(create: (_) => CartCubit()),
          ],
          child: CatalogPage(
            user: admin,
            checkoutRepository: checkoutRepository,
            outletId: state.shift.outletId,
            activeShift: state.shift,
            onManageShift: onManageShift,
          ),
        ),
        ShiftsClosing() => Scaffold(
          appBar: const CashierAppBar(),
          body: ShiftStatusView(
            user: admin,
            shift: state.shift,
            isClosing: true,
          ),
        ),
        ShiftsClosed() => Scaffold(
          appBar: const CashierAppBar(),
          body: ShiftStatusView(
            user: admin,
            shift: state.shift,
            isClosed: true,
          ),
        ),
        ShiftsFailure() => Scaffold(
          appBar: const CashierAppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Shift belum dapat diperiksa',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: context.read<ShiftsCubit>().loadActive,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      },
    );
  }
}

class CashierAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CashierAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        const Text('Kasir'),
      ],
    ),
  );
}
