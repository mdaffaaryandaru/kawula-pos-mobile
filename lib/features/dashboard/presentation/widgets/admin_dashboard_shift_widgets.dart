// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_models.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_state_widgets.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_state.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_action_dialog.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class ShiftStatusBanner extends StatelessWidget {
  const ShiftStatusBanner({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftsCubit, ShiftsState>(
      builder: (context, state) => switch (state) {
        ShiftsLoading() => const DashboardBannerShell(
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Memeriksa status shift...'),
            ],
          ),
        ),
        ShiftsActive() => _ActiveShiftBanner(user: user, shift: state.shift),
        ShiftsNeedsOpening() => DashboardBannerShell(
          child: Row(
            children: [
              const DashboardStatusDot(color: AppColors.warning),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum ada shift aktif',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Buka shift untuk mulai bertransaksi.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => showShiftActionDialog(
                  context,
                  user: user,
                  mode: ShiftDialogMode.opening,
                ),
                child: const Text('Open Shift'),
              ),
            ],
          ),
        ),
        ShiftsOpening() => const DashboardBannerShell(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Shift sedang dibuka'),
          ),
        ),
        ShiftsClosing() => const DashboardBannerShell(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Shift sedang ditutup'),
          ),
        ),
        ShiftsClosed() => DashboardBannerShell(
          child: Row(
            children: [
              const DashboardStatusDot(color: AppColors.textSecondary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Shift sudah ditutup',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: context.read<ShiftsCubit>().loadActive,
                child: const Text('Perbarui'),
              ),
            ],
          ),
        ),
        ShiftsFailure() => DashboardBannerShell(
          child: Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Status shift belum tersedia: ${state.message}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Coba periksa shift lagi',
                onPressed: context.read<ShiftsCubit>().loadActive,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      },
    );
  }
}

class _ActiveShiftBanner extends StatelessWidget {
  const _ActiveShiftBanner({required this.user, required this.shift});

  final AuthUser user;
  final ActiveShift shift;

  @override
  Widget build(BuildContext context) {
    return DashboardBannerShell(
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const DashboardStatusDot(color: AppColors.success),
          const Text(
            'Shift Aktif',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${shift.outletName ?? 'Outlet'} · '
            'Modal awal ${formatDashboardRupiah(shift.startingCash)} · '
            '${shift.totalTransactions} transaksi',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          OutlinedButton(
            onPressed: () => showShiftActionDialog(
              context,
              user: user,
              mode: ShiftDialogMode.closing,
            ),
            child: const Text('Tutup Shift'),
          ),
        ],
      ),
    );
  }
}
