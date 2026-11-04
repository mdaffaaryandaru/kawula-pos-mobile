// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_dialog_components.dart';
import 'package:kawula_pos/features/shifts/presentation/widgets/shift_formatters.dart';

class ShiftOpenForm extends StatelessWidget {
  const ShiftOpenForm({
    super.key,
    required this.formKey,
    required this.user,
    required this.startingCashController,
    required this.pinController,
    required this.availability,
    required this.isOpening,
    required this.onOpen,
    required this.onClose,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final AuthUser user;
  final TextEditingController startingCashController;
  final TextEditingController pinController;
  final CashAvailability availability;
  final bool isOpening;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final canOpen =
        user.hasPin && availability.availableCash >= 0 && !isOpening;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShiftDialogHeader(
            title: 'Buka Shift Kasir',
            subtitle: 'Masukkan modal awal laci dan PIN Anda.',
            icon: Icons.lock_open_rounded,
            onClose: isOpening ? null : onClose,
          ),
          const SizedBox(height: 20),
          _AvailabilityCard(availability: availability),
          const SizedBox(height: 16),
          if (!user.hasPin)
            const Text(
              'PIN belum diatur. Hubungi admin untuk mengatur PIN sebelum membuka shift.',
            )
          else ...[
            TextFormField(
              controller: startingCashController,
              enabled: !isOpening,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              decoration: const InputDecoration(
                labelText: 'Modal awal (Rp)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = num.tryParse(value?.trim() ?? '');
                if (amount == null || amount < 0) {
                  return 'Masukkan nominal yang valid.';
                }
                if (amount > availability.availableCash) {
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
                labelText: 'PIN (4 digit)',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || !RegExp(r'^\d{4}$').hasMatch(value)) {
                  return 'PIN harus terdiri dari 4 angka.';
                }
                return null;
              },
            ),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            ShiftErrorMessage(errorMessage!),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canOpen ? onOpen : null,
            child: isOpening
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mulai Shift'),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.availability});

  final CashAvailability availability;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kas tersedia'),
        const SizedBox(height: 4),
        Text(
          formatShiftRupiah(availability.availableCash),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
