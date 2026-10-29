import 'package:flutter/material.dart';

class MasterDataSearchPanel extends StatelessWidget {
  const MasterDataSearchPanel({
    super.key,
    required this.controller,
    required this.query,
    required this.hintText,
    required this.onChanged,
    this.trailing,
  });

  final TextEditingController controller;
  final String query;
  final String hintText;
  final ValueChanged<String> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 620;
      final searchField = TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
        ),
      );

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: trailing == null
            ? searchField
            : compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [searchField, const SizedBox(height: 12), trailing!],
              )
            : Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 16),
                  SizedBox(width: 220, child: trailing),
                ],
              ),
      );
    },
  );
}
