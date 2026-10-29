import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/balance.dart';
import 'balance_formatters.dart';

class BalanceHistorySection extends StatefulWidget {
  const BalanceHistorySection({super.key, required this.history});

  final List<BalanceHistoryEntry> history;

  @override
  State<BalanceHistorySection> createState() => _BalanceHistorySectionState();
}

class _BalanceHistorySectionState extends State<BalanceHistorySection> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildHistory(context);

  Widget _buildHistory(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final history = widget.history
        .where((entry) {
          final searchable = [
            entry.paymentMethod,
            historyTypeLabel(entry.type),
            entry.notes,
            entry.createdBy ?? '',
            entry.createdByEmail ?? '',
          ].join(' ').toLowerCase();
          return searchable.contains(normalizedQuery);
        })
        .toList(growable: false);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final title = Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Riwayat Mutasi Saldo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                );
                final search = SizedBox(
                  width: constraints.maxWidth >= 760
                      ? 280
                      : constraints.maxWidth,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari catatan, metode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                );
                return constraints.maxWidth >= 760
                    ? Row(
                        children: [
                          Expanded(child: title),
                          search,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [title, const SizedBox(height: 12), search],
                      );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: FinanceEmptyState(
                icon: Icons.receipt_long_outlined,
                message: widget.history.isEmpty
                    ? 'Belum ada riwayat mutasi saldo.'
                    : 'Tidak ada mutasi yang cocok dengan pencarian.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 760
                  ? Column(
                      children: [
                        for (final entry in history)
                          BalanceHistoryCard(entry: entry),
                      ],
                    )
                  : _historyTable(history, constraints.maxWidth),
            ),
        ],
      ),
    );
  }

  Widget _historyTable(
    List<BalanceHistoryEntry> history,
    double availableWidth,
  ) {
    const columnWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(210),
      1: FixedColumnWidth(150),
      2: FixedColumnWidth(120),
      3: FixedColumnWidth(160),
      4: FixedColumnWidth(170),
      5: FixedColumnWidth(160),
      6: FlexColumnWidth(),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: availableWidth > 1250 ? availableWidth : 1250,
        child: Table(
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFFAFCFF)),
              children: [
                for (final heading in [
                  'WAKTU',
                  'METODE',
                  'JENIS',
                  'MUTASI',
                  'SALDO AKHIR',
                  'OLEH',
                  'CATATAN',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 17,
                    ),
                    child: Text(
                      heading,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
              ],
            ),
            for (final entry in history)
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                children: [
                  _historyCell(
                    entry.createdAt == null
                        ? '—'
                        : formatBalanceDateTime(entry.createdAt!),
                  ),
                  _historyCell(paymentMethodLabel(entry.paymentMethod)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    child: HistoryTypeBadge(type: entry.type),
                  ),
                  _historyCell(
                    signedBalanceAmount(entry.amount),
                    color: entry.amount >= 0
                        ? AppColors.success
                        : AppColors.danger,
                    bold: true,
                  ),
                  _historyCell(
                    formatBalanceRupiah(entry.finalBalance),
                    bold: true,
                  ),
                  _historyCell(entry.createdBy ?? entry.createdByEmail ?? '—'),
                  _historyCell(
                    entry.notes.isEmpty ? '—' : entry.notes,
                    maxLines: 2,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _historyCell(
    String text, {
    Color color = AppColors.textPrimary,
    bool bold = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    ),
  );
}

class HistoryTypeBadge extends StatelessWidget {
  const HistoryTypeBadge({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type.toLowerCase()) {
      'sales' || 'refund' => AppColors.primary,
      'expense' => AppColors.warning,
      'adjustment' || 'initial' => const Color(0xFF64748B),
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        historyTypeLabel(type).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class BalanceHistoryCard extends StatelessWidget {
  const BalanceHistoryCard({super.key, required this.entry});

  final BalanceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.amount > 0
        ? const Color(0xFF16834A)
        : entry.amount < 0
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final icon = entry.amount > 0
        ? Icons.south_west
        : entry.amount < 0
        ? Icons.north_east
        : Icons.swap_horiz;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentMethodLabel(entry.paymentMethod),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.createdAt == null
                          ? 'Waktu tidak tersedia'
                          : formatBalanceDateTime(entry.createdAt!),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                signedBalanceAmount(entry.amount),
                textAlign: TextAlign.end,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              HistoryTypeBadge(type: entry.type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saldo akhir ${formatBalanceRupiah(entry.finalBalance)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.notes,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (entry.createdBy != null || entry.createdByEmail != null) ...[
            const SizedBox(height: 6),
            Text(
              'Oleh ${entry.createdBy ?? entry.createdByEmail}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FinanceEmptyState extends StatelessWidget {
  const FinanceEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
