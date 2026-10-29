part of '../pages/admin_transaction_report_page.dart';

class _ReportFilters extends StatelessWidget {
  const _ReportFilters({
    required this.startDate,
    required this.endDate,
    required this.query,
    required this.status,
    required this.payment,
    required this.paymentMethods,
    required this.resultCount,
    required this.onChooseRange,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onPaymentChanged,
    required this.onExport,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String query;
  final String status;
  final String payment;
  final List<String> paymentMethods;
  final int resultCount;
  final VoidCallback onChooseRange;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPaymentChanged;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Cari ID, nama produk, atau pembayaran...',
            prefixIcon: const Icon(Icons.search_rounded, size: 19),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: () => onQueryChanged(''),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
            filled: true,
            fillColor: AppColors.dashboardBackground,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
        );
        final date = OutlinedButton.icon(
          onPressed: onChooseRange,
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: Text(
            '${_formatDate(startDate)} – ${_formatDate(endDate)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
        final statusField = _filterDropdown(
          value: status,
          label: 'Semua Status',
          options: const [
            ('all', 'Semua Status'),
            ('completed', 'Selesai'),
            ('pending', 'Open bill'),
            ('cancelled', 'Dibatalkan'),
            ('refunded', 'Refund'),
          ],
          onChanged: onStatusChanged,
        );
        final paymentField = _filterDropdown(
          value: payment,
          label: 'Semua Pembayaran',
          options: [
            const ('all', 'Semua Pembayaran'),
            if (payment != 'all' &&
                !paymentMethods.any(
                  (method) => method.toLowerCase() == payment,
                ))
              (payment, payment),
            ...paymentMethods.map((method) => (method.toLowerCase(), method)),
          ],
          onChanged: onPaymentChanged,
        );
        final export = OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.download_outlined, size: 17),
          label: const Text('CSV'),
        );

        if (constraints.maxWidth >= 950) {
          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 8),
              SizedBox(width: 180, child: date),
              const SizedBox(width: 8),
              Expanded(child: statusField),
              const SizedBox(width: 8),
              Expanded(child: paymentField),
              const SizedBox(width: 8),
              export,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(width: 190, child: date),
                SizedBox(width: 170, child: statusField),
                SizedBox(width: 190, child: paymentField),
                export,
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$resultCount transaksi ditemukan',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _filterDropdown({
    required String value,
    required String label,
    required List<(String, String)> options,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      filled: true,
      fillColor: AppColors.dashboardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
    ),
    items: options
        .map(
          (option) => DropdownMenuItem(
            value: option.$1,
            child: Text(option.$2, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(growable: false),
    onChanged: onChanged,
  );
}
