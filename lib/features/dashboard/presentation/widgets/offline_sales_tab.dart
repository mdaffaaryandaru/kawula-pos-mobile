// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/transactions/application/offline_sales_repository_factory.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/products/presentation/bloc/catalog_cubit.dart';
import 'package:kawula_pos/features/products/presentation/pages/catalog_page.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_state.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_action_dialog.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/offline_transaction_queue_repository.dart';
import 'package:kawula_pos/features/transactions/domain/services/offline_transaction_sync.dart';
import 'package:kawula_pos/features/transactions/domain/services/offline_transaction_reconciliation.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/offline_transaction_queue_page.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/admin_offline_reconciliation_page.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/auto_close_settings_provider.dart';
import 'package:kawula_pos/framework/core/offline/offline_master_data_cache.dart';
import 'package:kawula_pos/framework/core/offline/offline_sales_policy.dart';

class OfflineSalesTab extends StatelessWidget {
  const OfflineSalesTab({
    super.key,
    required this.admin,
    required this.offlineSalesRepositoryFactory,
    required this.offlineTransactionQueueRepository,
    this.offlineTransactionReconciliation,
    this.offlineTransactionSyncService,
    this.offlineMasterDataCache,
    required this.autoCloseSettingsProvider,
    this.catalogPageKey,
  });

  final AuthUser admin;
  final OfflineSalesRepositoryFactory offlineSalesRepositoryFactory;
  final OfflineTransactionQueueRepository offlineTransactionQueueRepository;
  final OfflineTransactionReconciliation? offlineTransactionReconciliation;
  final OfflineTransactionSync? offlineTransactionSyncService;
  final OfflineMasterDataCache? offlineMasterDataCache;
  final AutoCloseSettingsProvider autoCloseSettingsProvider;
  final GlobalKey<CatalogPageState>? catalogPageKey;

  Future<int> _loadUnresolvedCount(ActiveShift activeShift) {
    final outletId = activeShift.outletId;
    if (outletId == null || outletId.trim().isEmpty) {
      throw StateError('Outlet shift tidak tersedia untuk memeriksa antrean.');
    }
    return offlineTransactionQueueRepository.getUnresolvedTransactionCount(
      ownerUserId: admin.id,
      outletId: outletId,
      shiftId: activeShift.id,
    );
  }

  Widget _buildActiveShift(BuildContext context, ActiveShift shift) {
    final shiftsCubit = context.read<ShiftsCubit>();
    final scope = offlineSalesRepositoryFactory.createScope(
      user: admin,
      shift: shift,
    );
    final scopedCache = scope.masterDataCache;
    final offlineTransactionSyncService = this.offlineTransactionSyncService;
    final offlineTransactionReconciliation =
        this.offlineTransactionReconciliation;

    return MultiBlocProvider(
      key: ValueKey<(String, String, String?, String)>((
        admin.id,
        admin.role,
        shift.outletId,
        shift.id,
      )),
      providers: [
        BlocProvider(
          create: (_) => CatalogCubit(scope.catalogRepository)..load(),
        ),
        BlocProvider(create: (_) => CartCubit()),
      ],
      child: CatalogPage(
        key: catalogPageKey,
        user: admin,
        checkoutRepository: scope.checkoutRepository,
        offlineTransactionQueueRepository: offlineTransactionQueueRepository,
        outletId: shift.outletId,
        activeShift: shift,
        offlineTransactionSyncService: offlineTransactionSyncService,
        autoCloseSettingsProvider: autoCloseSettingsProvider,
        offlineMasterDataCache: scopedCache,
        onOpenOfflineReconciliation:
            admin.role == 'Admin' &&
                offlineTransactionReconciliation != null &&
                shift.outletId != null &&
                shift.outletId!.isNotEmpty
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AdminOfflineReconciliationPage(
                      admin: admin,
                      outletId: shift.outletId!,
                      queueRepository: offlineTransactionQueueRepository,
                      reconciliation: offlineTransactionReconciliation,
                      isOutletActive: () {
                        final currentState = shiftsCubit.state;
                        return currentState is ShiftsActive &&
                            currentState.shift.outletId == shift.outletId;
                      },
                      outletActiveStream: shiftsCubit.stream.map((state) {
                        return state is ShiftsActive &&
                            state.shift.outletId == shift.outletId;
                      }),
                      offlineMasterDataCache: scopedCache,
                    ),
                  ),
                );
              }
            : null,
        onManageShift: () {
          if (scopedCache != null &&
              scopedCache.networkStatus != OfflineNetworkStatus.online) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pengelolaan shift memerlukan koneksi internet.'),
              ),
            );
            return;
          }
          showShiftActionDialog(
            context,
            user: admin,
            mode: ShiftDialogMode.closing,
            loadUnresolvedOfflineTransactionCount:
                canUseOfflineSales(admin.role) ? _loadUnresolvedCount : null,
            onOpenOfflineQueue:
                canUseOfflineSales(admin.role) &&
                    offlineTransactionSyncService != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OfflineTransactionQueuePage(
                          user: admin,
                          outletId: shift.outletId ?? '',
                          shiftId: shift.id,
                          queueRepository: offlineTransactionQueueRepository,
                          syncService: offlineTransactionSyncService,
                          offlineMasterDataCache: scopedCache,
                        ),
                      ),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftsCubit, ShiftsState>(
      builder: (context, state) => switch (state) {
        ShiftsLoading() => const Scaffold(
          appBar: OfflineSalesAppBar(),
          body: Center(child: CircularProgressIndicator()),
        ),
        ShiftsNeedsOpening()
            when offlineMasterDataCache != null &&
                offlineMasterDataCache!.networkStatus !=
                    OfflineNetworkStatus.online =>
          _shiftRequiresConnection(context),
        ShiftsNeedsOpening() => Scaffold(
          appBar: const OfflineSalesAppBar(),
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
          appBar: const OfflineSalesAppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
        ShiftsActive() => _buildActiveShift(context, state.shift),
        ShiftsClosing() => Scaffold(
          appBar: const OfflineSalesAppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
        ShiftsClosed() => Scaffold(
          appBar: const OfflineSalesAppBar(),
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
          appBar: const OfflineSalesAppBar(),
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

  Widget _shiftRequiresConnection(BuildContext context) => Scaffold(
    appBar: const OfflineSalesAppBar(),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Shift aktif tidak tersedia secara lokal.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Buka shift harus dilakukan saat online sebelum Offline Sales.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class OfflineSalesAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const OfflineSalesAppBar({super.key});

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
