// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:kawula_pos/features/auth/presentation/pages/login_page.dart';
import 'package:kawula_pos/features/auth/presentation/widgets/auth_loading_view.dart';
import 'package:kawula_pos/features/auth/presentation/widgets/auth_session_failure_view.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/dashboard/application/admin_dependencies.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/admin_navigation_page.dart';
import 'package:kawula_pos/features/dashboard/presentation/pages/cashier_navigation_page.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/auto_close_settings_provider.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/features/transactions/domain/services/offline_transaction_sync.dart';
import 'package:kawula_pos/features/transactions/application/offline_sales_repository_factory.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.adminDependencies,
    required this.checkoutRepository,
    required this.offlineTransactionQueueRepository,
    required this.offlineSalesRepositoryFactory,
    required this.balancesRepository,
    required this.autoCloseSettingsProvider,
    this.masterDataCache,
    this.offlineTransactionSyncService,
  });

  final AdminDependencies adminDependencies;
  final CheckoutRepository checkoutRepository;
  final OfflineTransactionQueueRepository offlineTransactionQueueRepository;
  final OfflineSalesRepositoryFactory offlineSalesRepositoryFactory;
  final BalancesRepository balancesRepository;
  final AutoCloseSettingsProvider autoCloseSettingsProvider;
  final OfflineMasterDataCache? masterDataCache;
  final OfflineTransactionSync? offlineTransactionSyncService;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthChecking() => const AuthLoadingView(),
          AuthSubmitting() => const LoginPage(),
          AuthUnauthenticated() => LoginPage(errorMessage: state.errorMessage),
          AuthAuthenticated() when state.user.role == 'Admin' =>
            AdminNavigationPage(
              key: ValueKey<(String, String)>((state.user.id, state.user.role)),
              admin: state.user,
              adminDependencies: adminDependencies,
              shiftsRepository: offlineSalesRepositoryFactory
                  .shiftsRepositoryFor(state.user),
              masterDataCache: masterDataCache,
              offlineTransactionSyncService: offlineTransactionSyncService,
              checkoutRepository: checkoutRepository,
              offlineTransactionQueueRepository:
                  offlineTransactionQueueRepository,
              offlineSalesRepositoryFactory: offlineSalesRepositoryFactory,
              balancesRepository: balancesRepository,
              autoCloseSettingsProvider: autoCloseSettingsProvider,
            ),
          AuthAuthenticated()
              when state.user.role == 'Kasir' && masterDataCache != null =>
            CashierNavigationPage(
              key: ValueKey<(String, String)>((state.user.id, state.user.role)),
              user: state.user,
              offlineMasterDataCache: masterDataCache,
              shiftsRepository: offlineSalesRepositoryFactory
                  .shiftsRepositoryFor(state.user),
              checkoutRepository: checkoutRepository,
              offlineTransactionQueueRepository:
                  offlineTransactionQueueRepository,
              offlineSalesRepositoryFactory: offlineSalesRepositoryFactory,
              balancesRepository: balancesRepository,
              offlineTransactionSyncService: offlineTransactionSyncService,
              autoCloseSettingsProvider: autoCloseSettingsProvider,
            ),
          AuthAuthenticated() => CashierNavigationPage(
            key: ValueKey<(String, String)>((state.user.id, state.user.role)),
            user: state.user,
            shiftsRepository: offlineSalesRepositoryFactory.shiftsRepositoryFor(
              state.user,
            ),
            checkoutRepository: checkoutRepository,
            offlineTransactionQueueRepository:
                offlineTransactionQueueRepository,
            offlineSalesRepositoryFactory: offlineSalesRepositoryFactory,
            balancesRepository: balancesRepository,
            offlineTransactionSyncService: offlineTransactionSyncService,
            autoCloseSettingsProvider: autoCloseSettingsProvider,
          ),
          AuthSessionFailure() => AuthSessionFailureView(
            message: state.message,
          ),
        };
      },
    );
  }
}
