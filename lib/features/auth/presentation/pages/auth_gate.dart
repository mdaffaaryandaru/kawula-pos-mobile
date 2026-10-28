import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';
import '../../../balances/domain/repositories/balances_repository.dart';
import '../../../categories/domain/repositories/categories_repository.dart';
import '../../../shifts/domain/repositories/shifts_repository.dart';
import '../../../shifts/presentation/bloc/shifts_cubit.dart';
import '../../../shifts/presentation/pages/shift_page.dart';
import '../../../products/domain/repositories/catalog_repository.dart';
import '../../../transactions/domain/repositories/checkout_repository.dart';
import '../../../users/domain/repositories/user_management_repository.dart';
import '../../../products/domain/repositories/product_management_repository.dart';
import '../../../dashboard/presentation/pages/admin_navigation_page.dart';
import '../../../variant_groups/domain/repositories/variant_groups_repository.dart';
import '../../../store_settings/domain/repositories/store_settings_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.shiftsRepository,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.balancesRepository,
    required this.storeSettingsRepository,
    required this.apiBaseUrl,
    required this.userManagementRepository,
    required this.productManagementRepository,
    required this.categoriesRepository,
    required this.variantGroupsRepository,
  });

  final ShiftsRepository shiftsRepository;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final BalancesRepository balancesRepository;
  final StoreSettingsRepository storeSettingsRepository;
  final String apiBaseUrl;
  final UserManagementRepository userManagementRepository;
  final ProductManagementRepository productManagementRepository;
  final CategoriesRepository categoriesRepository;
  final VariantGroupsRepository variantGroupsRepository;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthChecking() => const _LoadingPage(),
          AuthSubmitting() => LoginPage(),
          AuthUnauthenticated() => LoginPage(errorMessage: state.errorMessage),
          AuthAuthenticated() when state.user.role == 'Admin' =>
            AdminNavigationPage(
              admin: state.user,
              shiftsRepository: shiftsRepository,
              catalogRepository: catalogRepository,
              checkoutRepository: checkoutRepository,
              balancesRepository: balancesRepository,
              storeSettingsRepository: storeSettingsRepository,
              apiBaseUrl: apiBaseUrl,
              userManagementRepository: userManagementRepository,
              productManagementRepository: productManagementRepository,
              categoriesRepository: categoriesRepository,
              variantGroupsRepository: variantGroupsRepository,
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
