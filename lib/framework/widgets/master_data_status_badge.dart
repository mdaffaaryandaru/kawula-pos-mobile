import 'package:flutter/material.dart';

class MasterDataStatusBadge extends StatelessWidget {
  const MasterDataStatusBadge({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(isActive ? 'Aktif' : 'Nonaktif'),
    visualDensity: VisualDensity.compact,
    backgroundColor: isActive
        ? Colors.green.withValues(alpha: .1)
        : Colors.grey.withValues(alpha: .15),
    labelStyle: TextStyle(
      color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
    ),
    side: BorderSide.none,
  );
}
