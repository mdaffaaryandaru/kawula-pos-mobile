part of '../pages/admin_dashboard_page.dart';

class _DashboardActions extends StatelessWidget {
  const _DashboardActions({
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
        ShiftsNeedsOpening() => _DashboardAction(
          label: 'Open Shift',
          icon: Icons.lock_open_rounded,
          color: AppColors.primary,
          onTap: () => showShiftActionDialog(
            context,
            user: user,
            mode: ShiftDialogMode.opening,
          ),
        ),
        ShiftsActive() => _DashboardAction(
          label: 'Close Shift',
          icon: Icons.lock_outline_rounded,
          color: AppColors.danger,
          onTap: () => showShiftActionDialog(
            context,
            user: user,
            mode: ShiftDialogMode.closing,
          ),
        ),
        ShiftsFailure() => _DashboardAction(
          label: 'Coba Lagi',
          icon: Icons.refresh_rounded,
          color: AppColors.warning,
          onTap: context.read<ShiftsCubit>().loadActive,
        ),
        ShiftsLoading() ||
        ShiftsOpening() ||
        ShiftsClosing() ||
        ShiftsClosed() => _DashboardAction(
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
        _DashboardAction(
          label: 'Transaksi Baru · Buka Kasir',
          icon: Icons.point_of_sale_rounded,
          color: AppColors.success,
          onTap: onNewTransaction,
        ),
        _DashboardAction(
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

  final _DashboardAction action;

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
