import 'package:flutter/material.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/active_shift.dart';
import 'shift_formatters.dart';
import 'shift_status_widgets.dart';

class ActiveShiftView extends StatelessWidget {
  const ActiveShiftView({
    super.key,
    required this.user,
    required this.shift,
    required this.errorMessage,
    required this.isClosing,
    required this.isCloseFormVisible,
    required this.closeFormKey,
    required this.actualCashController,
    required this.closePinController,
    required this.notesController,
    required this.onShowCloseForm,
    required this.onHideCloseForm,
    required this.onConfirmClose,
    required this.onRefresh,
  });

  final AuthUser user;
  final ActiveShift shift;
  final String? errorMessage;
  final bool isClosing;
  final bool isCloseFormVisible;
  final GlobalKey<FormState> closeFormKey;
  final TextEditingController actualCashController;
  final TextEditingController closePinController;
  final TextEditingController notesController;
  final VoidCallback onShowCloseForm;
  final VoidCallback onHideCloseForm;
  final ValueChanged<bool> onConfirmClose;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Shift sedang berjalan',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Chip(
                              label: Text('AKTIF'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Color(0xFFC9F5E2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${shift.outletName ?? 'Outlet'} · '
                          'Mulai ${formatShiftTime(shift.startTime)}',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ShiftMetric(
                                label: 'Modal awal',
                                value: formatShiftRupiah(shift.startingCash),
                              ),
                            ),
                            Expanded(
                              child: ShiftMetric(
                                label: 'Transaksi',
                                value: '${shift.totalTransactions}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Halo, ${user.name}'),
                  const Divider(height: 32),
                  ShiftInfoRow(
                    label: 'Waktu mulai',
                    value: formatShiftDateTime(shift.startTime),
                  ),
                  ShiftInfoRow(
                    label: 'Kas yang diharapkan',
                    value: formatShiftRupiah(shift.expectedCash),
                  ),
                  ShiftInfoRow(
                    label: 'Total penjualan',
                    value: formatShiftRupiah(shift.totalSales),
                  ),
                  ShiftInfoRow(
                    label: 'Jumlah transaksi',
                    value: '${shift.totalTransactions}',
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                  if (isCloseFormVisible) ...[
                    const Divider(height: 32),
                    CloseShiftForm(
                      user: user,
                      shift: shift,
                      isClosing: isClosing,
                      formKey: closeFormKey,
                      actualCashController: actualCashController,
                      pinController: closePinController,
                      notesController: notesController,
                      onSubmit: onConfirmClose,
                      onCancel: onHideCloseForm,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (!isCloseFormVisible)
                    FilledButton.icon(
                      onPressed: isClosing ? null : onShowCloseForm,
                      icon: const Icon(Icons.lock_clock_outlined),
                      label: const Text('Tutup shift'),
                    ),
                  if (!isCloseFormVisible) const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isClosing ? null : onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Perbarui status'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CloseShiftForm extends StatelessWidget {
  const CloseShiftForm({
    super.key,
    required this.user,
    required this.shift,
    required this.isClosing,
    required this.formKey,
    required this.actualCashController,
    required this.pinController,
    required this.notesController,
    required this.onSubmit,
    required this.onCancel,
  });

  final AuthUser user;
  final ActiveShift shift;
  final bool isClosing;
  final GlobalKey<FormState> formKey;
  final TextEditingController actualCashController;
  final TextEditingController pinController;
  final TextEditingController notesController;
  final ValueChanged<bool> onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final requiresPin = user.role != 'Admin';
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tutup shift', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Hitung uang fisik di laci kasir sebelum mengisi kas aktual.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: actualCashController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: const InputDecoration(
              labelText: 'Kas aktual',
              prefixText: 'Rp ',
            ),
            validator: (value) {
              final amount = num.tryParse(value?.trim() ?? '');
              if (amount == null || amount < 0) {
                return 'Masukkan kas aktual yang valid.';
              }
              return null;
            },
          ),
          if (requiresPin) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'PIN kasir',
                prefixIcon: Icon(Icons.pin_outlined),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || !RegExp(r'^\d{4}$').hasMatch(value)) {
                  return 'PIN harus terdiri dari 4 angka.';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: notesController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          if (isClosing)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton(
              onPressed: () => onSubmit(requiresPin),
              child: const Text('Lanjutkan tutup shift'),
            ),
          TextButton(
            onPressed: isClosing ? null : onCancel,
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
}
