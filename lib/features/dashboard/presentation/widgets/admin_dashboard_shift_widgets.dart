part of '../pages/admin_dashboard_page.dart';

class _ShiftStatusBanner extends StatelessWidget {
  const _ShiftStatusBanner({required this.onOpenCashier});

  final VoidCallback onOpenCashier;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShiftsCubit, ShiftsState>(
      builder: (context, state) => switch (state) {
        ShiftsLoading() => const _BannerShell(
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
        ShiftsActive() => _ActiveShiftBanner(
          shift: state.shift,
          onOpenCashier: onOpenCashier,
        ),
        ShiftsNeedsOpening() => _BannerShell(
          child: Row(
            children: [
              const _StatusDot(color: AppColors.warning),
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
                onPressed: onOpenCashier,
                child: const Text('Buka shift'),
              ),
            ],
          ),
        ),
        ShiftsOpening() => const _BannerShell(
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
        ShiftsClosing() => const _BannerShell(
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
        ShiftsClosed() => _BannerShell(
          child: Row(
            children: [
              const _StatusDot(color: AppColors.textSecondary),
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
        ShiftsFailure() => _BannerShell(
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
  const _ActiveShiftBanner({required this.shift, required this.onOpenCashier});

  final ActiveShift shift;
  final VoidCallback onOpenCashier;

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _StatusDot(color: AppColors.success),
          const Text(
            'Shift Aktif',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${shift.outletName ?? 'Outlet'} · '
            'Modal awal ${_formatRupiah(shift.startingCash)} · '
            '${shift.totalTransactions} transaksi',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          OutlinedButton(
            onPressed: onOpenCashier,
            child: const Text('Kelola Shift'),
          ),
        ],
      ),
    );
  }
}
