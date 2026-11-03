// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/dashboard/presentation/widgets/admin_dashboard_models.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_cubit.dart';
import 'package:kawula_pos/features/shifts/presentation/bloc/shifts_state.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_action_dialog.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class DashboardActions extends StatelessWidget {
  const DashboardActions({
    super.key,
    required this.user,
    required this.onNewTransaction,
    required this.onOpenReport,
  });

  final AuthUser user;
  final VoidCallback onNewTransaction;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) => BlocBuilder<ShiftsCubit, ShiftsState>(
    builder: (context, state) {
      final shiftAction = switch (state) {
        ShiftsNeedsOpening() => DashboardAction(
          label: 'Open Shift',
          icon: Icons.lock_open_rounded,
          color: AppColors.primary,
          onTap: () => showShiftActionDialog(
            context,
            user: user,
            mode: ShiftDialogMode.opening,
          ),
        ),
        ShiftsActive() => DashboardAction(
          label: 'Close Shift',
          icon: Icons.lock_outline_rounded,
          color: AppColors.danger,
          onTap: () => showShiftActionDialog(
            context,
            user: user,
            mode: ShiftDialogMode.closing,
          ),
        ),
        ShiftsFailure() => DashboardAction(
          label: 'Coba Lagi',
          icon: Icons.refresh_rounded,
          color: AppColors.warning,
          onTap: context.read<ShiftsCubit>().loadActive,
        ),
        ShiftsLoading() ||
        ShiftsOpening() ||
        ShiftsClosing() ||
        ShiftsClosed() => DashboardAction(
          label: switch (state) {
            ShiftsOpening() => 'Membuka Shift...',
            ShiftsClosing() => 'Menutup Shift...',
            ShiftsClosed() => 'Memuat Status Shift...',
            _ => 'Memeriksa Shift...',
          },
          icon: Icons.sync_alt_rounded,
          color: AppColors.primary,
          onTap: () {},
          enabled: false,
        ),
      };
      final actions = [
        shiftAction,
        DashboardAction(
          label: 'Transaksi Baru · Buka Kasir',
          icon: Icons.point_of_sale_rounded,
          color: AppColors.success,
          onTap: onNewTransaction,
        ),
        DashboardAction(
          label: 'Riwayat Hari Ini',
          icon: Icons.trending_up_rounded,
          color: AppColors.navy,
          onTap: onOpenReport,
        ),
      ];
      return LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final width = constraints.maxWidth;
          final columns = width >= 720
              ? 3
              : width >= 480
              ? 2
              : 1;
          final cardWidth = (width - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: actions
                .map(
                  (action) => SizedBox(
                    width: cardWidth,
                    child: _ActionCard(action: action),
                  ),
                )
                .toList(),
          );
        },
      );
    },
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: action.color.withValues(alpha: .22),
      child: InkWell(
        onTap: action.enabled ? action.onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              Icon(action.icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
