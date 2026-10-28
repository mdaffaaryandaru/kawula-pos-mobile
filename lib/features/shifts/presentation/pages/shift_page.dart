import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../../products/presentation/bloc/cart_cubit.dart';
import '../../../products/presentation/bloc/catalog_cubit.dart';
import '../../../products/presentation/pages/catalog_page.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../transactions/presentation/pages/transactions_history_page.dart';
import '../bloc/shifts_cubit.dart';
import '../bloc/shifts_state.dart';
import 'shift_status_view.dart';

class ShiftPage extends StatelessWidget {
  const ShiftPage({
    super.key,
    required this.user,
    required this.catalogRepository,
    required this.checkoutRepository,
  });

  final AuthUser user;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            const Text('Kawula POS'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      TransactionsHistoryPage(repository: checkoutRepository),
                ),
              );
            },
            tooltip: 'Riwayat transaksi',
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            onPressed: context.read<AuthCubit>().logout,
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BlocBuilder<ShiftsCubit, ShiftsState>(
        builder: (context, state) {
          return switch (state) {
            ShiftsLoading() => const Center(child: CircularProgressIndicator()),
            ShiftsNeedsOpening() => ShiftStatusView(
              user: user,
              cashAvailability: state.cashAvailability,
              errorMessage: state.errorMessage,
              isOpening: false,
            ),
            ShiftsOpening() => ShiftStatusView(
              user: user,
              cashAvailability: state.cashAvailability,
              isOpening: true,
            ),
            ShiftsActive() => ShiftStatusView(
              user: user,
              shift: state.shift,
              errorMessage: state.errorMessage,
            ),
            ShiftsClosing() => ShiftStatusView(
              user: user,
              shift: state.shift,
              isClosing: true,
            ),
            ShiftsClosed() => ShiftStatusView(
              user: user,
              shift: state.shift,
              isClosed: true,
            ),
            ShiftsFailure() => _ShiftFailure(message: state.message),
          };
        },
      ),
      floatingActionButton: BlocBuilder<ShiftsCubit, ShiftsState>(
        builder: (context, state) {
          if (state is! ShiftsActive) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => CatalogCubit(catalogRepository)..load(),
                      ),
                      BlocProvider(create: (_) => CartCubit()),
                    ],
                    child: CatalogPage(
                      user: user,
                      checkoutRepository: checkoutRepository,
                      outletId: state.shift.outletId,
                      activeShift: state.shift,
                      onManageShift: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Ke kasir'),
          );
        },
      ),
    );
  }
}

class _ShiftFailure extends StatelessWidget {
  const _ShiftFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<ShiftsCubit>().loadActive,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
