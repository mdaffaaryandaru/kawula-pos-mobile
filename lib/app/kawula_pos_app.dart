// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/bootstrap/app_dependencies.dart';
import 'package:kawula_pos/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:kawula_pos/features/auth/presentation/pages/auth_gate.dart';
import 'package:kawula_pos/features/splash/presentation/pages/kawula_splash_screen.dart';
import 'package:kawula_pos/theme/app_theme.dart';

class KawulaPosApp extends StatelessWidget {
  const KawulaPosApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        dependencies.authRepository,
        sessionExpiryHandler: dependencies.sessionExpiryHandler,
      )..restoreSession(),
      child: MaterialApp(
        title: 'Kawula',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: KawulaSplashScreen(
          child: AuthGate(
            adminDependencies: dependencies.adminDependencies,
            offlineNetworkStatusController:
                dependencies.offlineNetworkStatusController,
            offlineTransactionSyncService:
                dependencies.offlineTransactionSyncService,
            checkoutRepository: dependencies.checkoutRepository,
            offlineTransactionQueueRepository:
                dependencies.offlineTransactionQueueRepository,
            offlineSalesRepositoryFactory:
                dependencies.offlineSalesRepositoryFactory,
            balancesRepository: dependencies.balancesRepository,
            autoCloseSettingsProvider: dependencies.autoCloseSettingsProvider,
          ),
        ),
      ),
    );
  }
}
