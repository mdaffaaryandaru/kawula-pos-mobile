import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../../products/presentation/bloc/cart_cubit.dart';
import '../../../products/presentation/bloc/catalog_cubit.dart';
import '../../../products/presentation/pages/catalog_page.dart';
import '../../../shifts/presentation/bloc/shifts_cubit.dart';
import '../../../shifts/presentation/bloc/shifts_state.dart';
import '../../../shifts/presentation/widgets/shift_action_dialog.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';

class CashierTab extends StatelessWidget {
  const CashierTab({
    super.key,
    required this.admin,
    required this.catalogRepository,
    required this.checkoutRepository,
  });

  final AuthUser admin;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;

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
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_clock_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada shift aktif',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Buka shift untuk mulai menggunakan kasir.',
                      textAlign: TextAlign.center,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => showShiftActionDialog(
                        context,
                        user: admin,
                        mode: ShiftDialogMode.opening,
                      ),
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Open Shift'),
                    ),
                    TextButton(
                      onPressed: context.read<ShiftsCubit>().loadActive,
                      child: const Text('Perbarui status'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ShiftsOpening() => Scaffold(
          appBar: const CashierAppBar(),
          body: const Center(
            child: CircularProgressIndicator(),
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
            onManageShift: () => showShiftActionDialog(
              context,
              user: admin,
              mode: ShiftDialogMode.closing,
            ),
          ),
        ),
        ShiftsClosing() => Scaffold(
          appBar: const CashierAppBar(),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        ShiftsClosed() => Scaffold(
          appBar: const CashierAppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.task_alt, size: 48, color: Colors.green),
                  const SizedBox(height: 12),
                  const Text('Shift berhasil ditutup'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: context.read<ShiftsCubit>().loadActive,
                    child: const Text('Selesai'),
                  ),
                ],
              ),
            ),
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
