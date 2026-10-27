import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../bloc/shifts_cubit.dart';
import '../../domain/entities/active_shift.dart';

class ShiftStatusView extends StatefulWidget {
  const ShiftStatusView({
    super.key,
    required this.user,
    this.shift,
    this.cashAvailability,
    this.errorMessage,
    this.isOpening = false,
    this.isClosing = false,
    this.isClosed = false,
  });

  final AuthUser user;
  final ActiveShift? shift;
  final CashAvailability? cashAvailability;
  final String? errorMessage;
  final bool isOpening;
  final bool isClosing;
  final bool isClosed;

  @override
  State<ShiftStatusView> createState() => _ShiftStatusViewState();
}

class _ShiftStatusViewState extends State<ShiftStatusView> {
  final _formKey = GlobalKey<FormState>();
  final _closeFormKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _pinController = TextEditingController();
  final _actualCashController = TextEditingController();
  final _closePinController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isCloseFormVisible = false;

  @override
  void initState() {
    super.initState();
    final shift = widget.shift;
    if (shift != null) {
      _actualCashController.text = shift.expectedCash.round().toString();
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _pinController.dispose();
    _actualCashController.dispose();
    _closePinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openShift() async {
    if (!_formKey.currentState!.validate()) return;
    final cash = num.parse(_cashController.text.trim());
    await context.read<ShiftsCubit>().openShift(
      startingCash: cash,
      pin: _pinController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    if (shift != null) {
      if (widget.isClosed) return _closedShift(context, shift);
      return _activeShift(context, shift);
    }
    return _openingShift(context);
  }

  Widget _activeShift(BuildContext context, ActiveShift shift) {
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
                  const Icon(Icons.check_circle, size: 52, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(
                    'Shift sedang berjalan',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Halo, ${widget.user.name}',
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 32),
                  if (shift.outletName case final outletName?)
                    _InfoRow(label: 'Outlet', value: outletName),
                  _InfoRow(
                    label: 'Mulai',
                    value: _formatDateTime(shift.startTime),
                  ),
                  _InfoRow(
                    label: 'Modal awal',
                    value: _formatRupiah(shift.startingCash),
                  ),
                  _InfoRow(
                    label: 'Kas yang diharapkan',
                    value: _formatRupiah(shift.expectedCash),
                  ),
                  _InfoRow(
                    label: 'Total penjualan',
                    value: _formatRupiah(shift.totalSales),
                  ),
                  _InfoRow(
                    label: 'Jumlah transaksi',
                    value: '${shift.totalTransactions}',
                  ),
                  if (widget.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_isCloseFormVisible) ...[
                    const Divider(height: 32),
                    _closeShiftForm(context, shift),
                  ],
                  const SizedBox(height: 20),
                  if (!_isCloseFormVisible)
                    FilledButton.icon(
                      onPressed: widget.isClosing
                          ? null
                          : () => setState(() => _isCloseFormVisible = true),
                      icon: const Icon(Icons.lock_clock_outlined),
                      label: const Text('Tutup shift'),
                    ),
                  if (!_isCloseFormVisible) const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.isClosing
                        ? null
                        : context.read<ShiftsCubit>().loadActive,
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

  Widget _closeShiftForm(BuildContext context, ActiveShift shift) {
    final requiresPin = widget.user.role != 'Admin';
    return Form(
      key: _closeFormKey,
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
            controller: _actualCashController,
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
              controller: _closePinController,
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
            controller: _notesController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.isClosing)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton(
              onPressed: () => _confirmCloseShift(context, shift, requiresPin),
              child: const Text('Lanjutkan tutup shift'),
            ),
          TextButton(
            onPressed: widget.isClosing
                ? null
                : () => setState(() => _isCloseFormVisible = false),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCloseShift(
    BuildContext context,
    ActiveShift shift,
    bool requiresPin,
  ) async {
    if (!_closeFormKey.currentState!.validate()) return;

    final actualCash = num.parse(_actualCashController.text.trim());
    final difference = actualCash - shift.expectedCash;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi tutup shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shift akan ditutup dan tidak dapat dibuka kembali.'),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Kas yang diharapkan',
              value: _formatRupiah(shift.expectedCash),
            ),
            _InfoRow(label: 'Kas aktual', value: _formatRupiah(actualCash)),
            _InfoRow(
              label: 'Perkiraan selisih',
              value: _formatRupiah(difference),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, tutup shift'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<ShiftsCubit>().closeShift(
      actualCash: actualCash,
      pin: requiresPin ? _closePinController.text : null,
      notes: _notesController.text,
    );
  }

  Widget _closedShift(BuildContext context, ActiveShift shift) {
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
                    _InfoRow(label: 'Selesai', value: _formatDateTime(endTime)),
                  _InfoRow(
                    label: 'Kas yang diharapkan',
                    value: _formatRupiah(shift.expectedCash),
                  ),
                  if (shift.actualCash case final actualCash?)
                    _InfoRow(
                      label: 'Kas aktual',
                      value: _formatRupiah(actualCash),
                    ),
                  if (shift.cashDifference case final difference?)
                    _InfoRow(
                      label: 'Selisih kas',
                      value: _formatRupiah(difference),
                    ),
                  _InfoRow(
                    label: 'Total penjualan',
                    value: _formatRupiah(shift.totalSales),
                  ),
                  _InfoRow(
                    label: 'Jumlah transaksi',
                    value: '${shift.totalTransactions}',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: context.read<ShiftsCubit>().loadActive,
                    child: const Text('Selesai'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _openingShift(BuildContext context) {
    final availability = widget.cashAvailability;
    final canOpen =
        widget.user.hasPin &&
        availability != null &&
        availability.availableCash >= 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_clock_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada shift aktif',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buka shift untuk mulai menggunakan kasir.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (availability != null) ...[
                      _InfoRow(
                        label: 'Kas tersedia',
                        value: _formatRupiah(availability.availableCash),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!widget.user.hasPin)
                      const Text(
                        'PIN belum diatur. Hubungi admin untuk mengatur PIN sebelum membuka shift.',
                        textAlign: TextAlign.center,
                      )
                    else ...[
                      TextFormField(
                        controller: _cashController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: false,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Modal awal',
                          prefixText: 'Rp ',
                        ),
                        validator: (value) {
                          final input = value?.trim() ?? '';
                          final amount = num.tryParse(input);
                          if (amount == null || amount < 0) {
                            return 'Masukkan nominal yang valid.';
                          }
                          if (availability != null &&
                              amount > availability.availableCash) {
                            return 'Modal melebihi kas yang tersedia.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: 'PIN kasir',
                          prefixIcon: Icon(Icons.pin_outlined),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null ||
                              !RegExp(r'^\d{4}$').hasMatch(value)) {
                            return 'PIN harus terdiri dari 4 angka.';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (widget.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (widget.user.hasPin)
                      FilledButton(
                        onPressed: !canOpen || widget.isOpening
                            ? null
                            : _openShift,
                        child: widget.isOpening
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Buka shift'),
                      ),
                    TextButton.icon(
                      onPressed: widget.isOpening
                          ? null
                          : context.read<ShiftsCubit>().loadActive,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Perbarui status'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRupiah(num amount) {
  final digits = amount.round().abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${amount < 0 ? '- ' : ''}Rp $grouped';
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final date = local.toIso8601String();
  return '${date.substring(0, 10)} ${date.substring(11, 16)}';
}
