import 'package:flutter/material.dart';

import '../../domain/entities/active_shift.dart';
import 'shift_formatters.dart';
import 'shift_status_widgets.dart';

class ClosedShiftView extends StatelessWidget {
  const ClosedShiftView({super.key, required this.shift, required this.onDone});

  final ActiveShift shift;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.task_alt, size: 52, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(
                    'Shift berhasil ditutup',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Divider(height: 32),
                  if (shift.endTime case final endTime?)
                    ShiftInfoRow(
                      label: 'Selesai',
                      value: formatShiftDateTime(endTime),
                    ),
                  ShiftInfoRow(
                    label: 'Kas yang diharapkan',
                    value: formatShiftRupiah(shift.expectedCash),
                  ),
                  if (shift.actualCash case final actualCash?)
                    ShiftInfoRow(
                      label: 'Kas aktual',
                      value: formatShiftRupiah(actualCash),
                    ),
                  if (shift.cashDifference case final difference?)
                    ShiftInfoRow(
                      label: 'Selisih kas',
                      value: formatShiftRupiah(difference),
                    ),
                  ShiftInfoRow(
                    label: 'Total penjualan',
                    value: formatShiftRupiah(shift.totalSales),
                  ),
                  ShiftInfoRow(
                    label: 'Jumlah transaksi',
                    value: '${shift.totalTransactions}',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: onDone, child: const Text('Selesai')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
