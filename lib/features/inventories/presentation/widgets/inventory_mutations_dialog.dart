import 'package:flutter/material.dart';

import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryMutationsDialog extends StatefulWidget {
  const InventoryMutationsDialog({
    super.key,
    required this.repository,
    required this.item,
  });

  final InventoryRepository repository;
  final InventoryItem item;

  @override
  State<InventoryMutationsDialog> createState() =>
      _InventoryMutationsDialogState();
}

class _InventoryMutationsDialogState extends State<InventoryMutationsDialog> {
  late final Future<List<InventoryMutation>> _mutationsFuture;

  @override
  void initState() {
    super.initState();
    _mutationsFuture = widget.repository.getMutations(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Riwayat stok · ${widget.item.name}'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<List<InventoryMutation>>(
          future: _mutationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'Riwayat stok gagal dimuat.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final mutations = snapshot.data ?? const <InventoryMutation>[];
            if (mutations.isEmpty) {
              return const SizedBox(
                height: 140,
                child: Center(child: Text('Belum ada riwayat mutasi stok.')),
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: mutations.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _MutationTile(
                  mutation: mutations[index],
                  unit: widget.item.unit.abbreviation,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _MutationTile extends StatelessWidget {
  const _MutationTile({required this.mutation, required this.unit});

  final InventoryMutation mutation;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (mutation.type) {
      'in' => ('Stok masuk', Icons.south_west_rounded, Colors.green),
      'out' => ('Stok keluar', Icons.north_east_rounded, Colors.deepOrange),
      _ => ('Terpakai untuk penjualan', Icons.point_of_sale, Colors.blue),
    };
    final date = mutation.createdAt == null
        ? 'Waktu tidak tersedia'
        : _formatDate(mutation.createdAt!.toLocal());
    final amount = mutation.type == 'in'
        ? '+${_format(mutation.quantity)}'
        : '-${_format(mutation.quantity)}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text('$label · $amount $unit'),
      subtitle: Text(
        [
          date,
          'Sisa stok: ${_format(mutation.currentStock)} $unit',
          if (mutation.notes.isNotEmpty) mutation.notes,
          if (mutation.createdBy?.isNotEmpty == true)
            'Oleh ${mutation.createdBy}',
          if (mutation.relatedProductName?.isNotEmpty == true)
            'Produk: ${mutation.relatedProductName}',
        ].join('\n'),
      ),
      isThreeLine: true,
    );
  }
}

String _format(num value) =>
    value == value.toInt() ? value.toInt().toString() : value.toString();

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
