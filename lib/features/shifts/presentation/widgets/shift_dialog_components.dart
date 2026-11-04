// Flutter imports:
import 'package:flutter/material.dart';

class ShiftDialogHeader extends StatelessWidget {
  const ShiftDialogHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.onClose,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ],
        ),
      ),
      IconButton(
        onPressed: onClose,
        tooltip: 'Tutup dialog',
        icon: const Icon(Icons.close),
        visualDensity: VisualDensity.compact,
      ),
    ],
  );
}

class ShiftDialogInfo extends StatelessWidget {
  const ShiftDialogInfo({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).hintColor),
      ),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class ShiftErrorMessage extends StatelessWidget {
  const ShiftErrorMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
    ),
  );
}
