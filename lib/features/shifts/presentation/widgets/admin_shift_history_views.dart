// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/framework/widgets/responsive_data_table.dart';
import 'package:kawula_pos/features/shifts/presentation/utils/admin_shift_formatters.dart';
import 'package:kawula_pos/theme/app_colors.dart';

class ShiftHistoryEmpty extends StatelessWidget {
  const ShiftHistoryEmpty({super.key});

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

class ShiftHistoryTable extends StatelessWidget {
  const ShiftHistoryTable({
    super.key,
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
                DataCell(ShiftStatusChip(status: shift.status)),
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

class ShiftCard extends StatelessWidget {
  const ShiftCard({super.key, required this.shift, required this.onTap});

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
                  ShiftStatusChip(status: shift.status),
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

class ShiftStatusChip extends StatelessWidget {
  const ShiftStatusChip({super.key, required this.status});

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
