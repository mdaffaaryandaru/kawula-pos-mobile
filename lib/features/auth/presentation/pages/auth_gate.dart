import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';
import '../../../shifts/domain/repositories/shifts_repository.dart';
import '../../../shifts/presentation/bloc/shifts_cubit.dart';
import '../../../shifts/presentation/pages/shift_page.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../users/domain/repositories/user_management_repository.dart';
import '../../../users/presentation/pages/admin_users_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.shiftsRepository,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.userManagementRepository,
  });

  final ShiftsRepository shiftsRepository;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final UserManagementRepository userManagementRepository;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthChecking() => const _LoadingPage(),
          AuthSubmitting() => LoginPage(),
          AuthUnauthenticated() => LoginPage(errorMessage: state.errorMessage),
          AuthAuthenticated() when state.user.role == 'Admin' => AdminUsersPage(
            admin: state.user,
            repository: userManagementRepository,
          ),
          AuthAuthenticated() => BlocProvider(
            create: (_) => ShiftsCubit(shiftsRepository)..loadActive(),
            child: ShiftPage(
              user: state.user,
              catalogRepository: catalogRepository,
              checkoutRepository: checkoutRepository,
            ),
          ),
          AuthSessionFailure() => _SessionFailurePage(message: state.message),
        };
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _SessionFailurePage extends StatelessWidget {
  const _SessionFailurePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Sesi belum dapat diperiksa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: context.read<AuthCubit>().restoreSession,
                child: const Text('Coba lagi'),
              ),
              TextButton(
                onPressed: context.read<AuthCubit>().logout,
                child: const Text('Keluar dari sesi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
