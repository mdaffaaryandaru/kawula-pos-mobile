import 'package:flutter/material.dart';

class MasterDataRowActions extends StatelessWidget {
  const MasterDataRowActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.leadingActions = const [],
    this.trailingActions = const [],
    this.deleteEnabled = true,
    this.deleteTooltip = 'Hapus',
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final List<Widget> leadingActions;
  final List<Widget> trailingActions;
  final bool deleteEnabled;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ...leadingActions,
      IconButton(
        tooltip: 'Edit',
        onPressed: onEdit,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.edit_outlined),
      ),
      ...trailingActions,
      IconButton(
        tooltip: deleteTooltip,
        onPressed: deleteEnabled ? onDelete : null,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        icon: const Icon(Icons.delete_outline),
      ),
    ],
  );
}

class MasterDataDeleteConfirmation {
  const MasterDataDeleteConfirmation._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ) ??
      false;
}
