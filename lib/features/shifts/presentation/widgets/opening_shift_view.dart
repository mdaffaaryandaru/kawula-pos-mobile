import 'package:flutter/material.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/active_shift.dart';
import 'shift_formatters.dart';

class OpeningShiftView extends StatelessWidget {
  const OpeningShiftView({
    super.key,
    required this.user,
    required this.cashAvailability,
    required this.errorMessage,
    required this.isOpening,
    required this.formKey,
    required this.cashController,
    required this.pinController,
    required this.onOpen,
    required this.onRefresh,
  });

  final AuthUser user;
  final CashAvailability? cashAvailability;
  final String? errorMessage;
  final bool isOpening;
  final GlobalKey<FormState> formKey;
  final TextEditingController cashController;
  final TextEditingController pinController;
  final VoidCallback onOpen;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final availability = cashAvailability;
    final canOpen =
        user.hasPin && availability != null && availability.availableCash >= 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Icon(
                        Icons.lock_clock_outlined,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada shift aktif',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Halo, ${user.name}. Buka shift untuk mulai menggunakan kasir.',
                    ),
                    const SizedBox(height: 20),
                    if (availability != null) ...[
                      _CashAvailabilityCard(availability: availability),
                      const SizedBox(height: 16),
                    ],
                    if (!user.hasPin)
                      const Text(
                        'PIN belum diatur. Hubungi admin untuk mengatur PIN sebelum membuka shift.',
                        textAlign: TextAlign.center,
                      )
                    else ...[
                      TextFormField(
                        controller: cashController,
                        enabled: !isOpening,
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
                        controller: pinController,
                        enabled: !isOpening,
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
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (user.hasPin)
                      FilledButton(
                        onPressed: !canOpen || isOpening ? null : onOpen,
                        child: isOpening
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
                      onPressed: isOpening ? null : onRefresh,
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

class _CashAvailabilityCard extends StatelessWidget {
  const _CashAvailabilityCard({required this.availability});

  final CashAvailability availability;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kas tersedia', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            formatShiftRupiah(availability.availableCash),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
