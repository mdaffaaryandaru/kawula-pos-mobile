part of '../pages/admin_shifts_page.dart';

class _AdminShiftsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AdminShiftsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(title: const _ShiftLogoTitle(title: 'Shift kasir'));
}

class _ShiftLogoTitle extends StatelessWidget {
  const _ShiftLogoTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text(title),
      ],
    );
  }
}

class _ShiftHistoryHeader extends StatelessWidget {
  const _ShiftHistoryHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 520;
    return Container(
      padding: EdgeInsets.all(isWide ? 28 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAPORAN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Riwayat Shift',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Memantau riwayat shift kasir, status, dan ringkasan kas.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isWide ? 'Refresh' : 'Muat ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftHistorySearch extends StatelessWidget {
  const _ShiftHistorySearch({
    required this.controller,
    required this.onChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Cari kasir, outlet, atau status...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        );
        final filter = DropdownButtonFormField<String>(
          initialValue: selectedStatus ?? 'all',
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Status',
            prefixIcon: const Icon(Icons.filter_list_rounded),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Semua shift')),
            DropdownMenuItem(value: 'open', child: Text('Sedang berjalan')),
            DropdownMenuItem(value: 'closed', child: Text('Ditutup manual')),
            DropdownMenuItem(
              value: 'auto_closed',
              child: Text('Ditutup otomatis'),
            ),
          ],
          onChanged: onStatusChanged,
        );

        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(width: 220, child: filter),
            ],
          );
        }
        return Column(children: [search, const SizedBox(height: 12), filter]);
      },
    ),
  );
}

class _ShiftHistoryEmpty extends StatelessWidget {
  const _ShiftHistoryEmpty();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Center(
      child: Text('Tidak ada shift yang cocok dengan filter.'),
    ),
  );
}

class _ShiftHistoryTable extends StatelessWidget {
  const _ShiftHistoryTable({
    required this.shifts,
    required this.minWidth,
    required this.onDetails,
    required this.onForceClose,
  });

  final List<ActiveShift> shifts;
  final double minWidth;
  final ValueChanged<ActiveShift> onDetails;
  final ValueChanged<ActiveShift> onForceClose;

  @override
  Widget build(BuildContext context) {
    final header = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
    );
    return ResponsiveDataTable(
      minWidth: minWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFC)),
      horizontalMargin: 18,
      columnSpacing: 18,
      dataRowMinHeight: 80,
      dataRowMaxHeight: 100,
      columns: [
        DataColumn(label: Text('KASIR', style: header)),
        DataColumn(label: Text('OUTLET', style: header)),
        DataColumn(label: Text('WAKTU SHIFT', style: header)),
        DataColumn(label: Text('KAS', style: header)),
        DataColumn(label: Text('RINGKASAN', style: header)),
        DataColumn(label: Text('STATUS', style: header)),
        DataColumn(label: Text('AKSI', style: header)),
      ],
      rows: shifts
          .map(
            (shift) => DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 145,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.cashierName ?? 'Kasir',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          shift.cashierEmail ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      shift.outletName ?? 'Outlet',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 190,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open: ${formatAdminShiftDateTime(shift.startTime)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Tutup: ${shift.endTime == null ? '-' : formatAdminShiftDateTime(shift.endTime)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 145,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Awal: ${formatAdminShiftRupiah(shift.startingCash)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Seharusnya: ${formatAdminShiftRupiah(shift.expectedCash)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Fisik: ${shift.actualCash == null ? '-' : formatAdminShiftRupiah(shift.actualCash!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 125,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${shift.totalTransactions} transaksi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          formatAdminShiftRupiah(shift.totalSales),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Selisih: ${shift.cashDifference == null ? '-' : formatAdminShiftRupiah(shift.cashDifference!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(_ShiftStatusChip(status: shift.status)),
                DataCell(
                  SizedBox(
                    width: shift.status == 'open' ? 185 : 92,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => onDetails(shift),
                          icon: const Icon(Icons.visibility_outlined, size: 15),
                          label: const Text('Detail'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                          ),
                        ),
                        if (shift.status == 'open')
                          OutlinedButton(
                            onPressed: () => onForceClose(shift),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: BorderSide(
                                color: AppColors.danger.withValues(alpha: .3),
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                              ),
                            ),
                            child: const Text('Tutup Paksa'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift, required this.onTap});

  final ActiveShift shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Text(
                      adminShiftInitials(shift.cashierName ?? 'Kasir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.cashierName ?? 'Kasir',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (shift.cashierEmail != null)
                          Text(
                            shift.cashierEmail!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ShiftStatusChip(status: shift.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shift.outletName ?? 'Outlet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.schedule_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(formatAdminShiftDateTime(shift.startTime)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ShiftCardMetric(
                      label: 'Modal awal',
                      value: formatAdminShiftRupiah(shift.startingCash),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShiftCardMetric(
                      label: 'Penjualan',
                      value: formatAdminShiftRupiah(shift.totalSales),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('${shift.totalTransactions} transaksi'),
                  const Spacer(),
                  Text(
                    'Detail',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftCardMetric extends StatelessWidget {
  const _ShiftCardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ShiftStatusChip extends StatelessWidget {
  const _ShiftStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'open';
    final color = isOpen ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
