part of '../pages/checkout_page.dart';

extension _CheckoutReceiptWidgets on _CheckoutPageState {
  Widget _completed(CheckoutResult result, CheckoutSettings settings) {
    final isPending = result.status.toLowerCase() == 'pending';
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isPending
                  ? theme.colorScheme.tertiaryContainer
                  : const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(
                  isPending
                      ? Icons.pending_actions_outlined
                      : Icons.check_circle_outline,
                  size: 40,
                  color: isPending
                      ? theme.colorScheme.onTertiaryContainer
                      : const Color(0xFF16834A),
                ),
                const SizedBox(height: 8),
                Text(
                  isPending
                      ? 'Open bill berhasil dibuat'
                      : 'Pembayaran berhasil',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending
                      ? 'Transaksi ini belum lunas'
                      : 'Transaksi berhasil dicatat',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (settings.storeName.isNotEmpty)
                    Text(
                      settings.storeName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  if (settings.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(settings.address, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  Text(
                    isPending ? 'OPEN BILL · BELUM LUNAS' : 'STRUK PEMBAYARAN',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPending
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ReceiptInfoRow(label: 'No. transaksi', value: result.id),
                  _ReceiptInfoRow(
                    label: 'Waktu',
                    value: result.createdAt == null
                        ? 'Tidak tersedia'
                        : _formatReceiptDate(result.createdAt!),
                  ),
                  if (_selectedMember case final member?)
                    _ReceiptInfoRow(
                      label: 'Member',
                      value: '${member.name} · ${member.phoneNumber}',
                    ),
                  if (_tableNumberController.text.trim().isNotEmpty)
                    _ReceiptInfoRow(
                      label: 'No. meja',
                      value: _tableNumberController.text.trim(),
                    ),
                  const Divider(height: 24),
                  if (result.items.isEmpty)
                    const Text(
                      'Rincian item tidak disertakan pada respons transaksi.',
                      textAlign: TextAlign.center,
                    )
                  else
                    for (final item in result.items) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity} × ${item.productName}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(formatRupiah(item.price * item.quantity)),
                        ],
                      ),
                      for (final variant in item.selectedVariants)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 2),
                          child: Text(
                            '${variant.groupName}: ${variant.optionName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (item.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 2),
                          child: Text(
                            'Catatan: ${item.notes}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  const Divider(height: 20),
                  if (result.subtotal != null)
                    _ReceiptInfoRow(
                      label: 'Subtotal',
                      value: formatRupiah(result.subtotal!),
                    ),
                  if (result.taxAmount != null)
                    _ReceiptInfoRow(
                      label: 'Pajak',
                      value: formatRupiah(result.taxAmount!),
                    ),
                  if (result.serviceCharge != null)
                    _ReceiptInfoRow(
                      label: 'Biaya layanan',
                      value: formatRupiah(result.serviceCharge!),
                    ),
                  if (result.discountAmount != null &&
                      result.discountAmount! > 0)
                    _ReceiptInfoRow(
                      label: 'Diskon',
                      value: '- ${formatRupiah(result.discountAmount!)}',
                    ),
                  _ReceiptInfoRow(
                    label: 'TOTAL',
                    value: formatRupiah(result.totalAmount),
                    emphasized: true,
                  ),
                  const Divider(height: 20),
                  _ReceiptInfoRow(label: 'Metode', value: result.paymentMethod),
                  if (isPending)
                    const _ReceiptInfoRow(
                      label: 'Status',
                      value: 'Belum lunas',
                      emphasized: true,
                    )
                  else ...[
                    _ReceiptInfoRow(
                      label: 'Dibayar',
                      value: formatRupiah(result.paidAmount),
                    ),
                    _ReceiptInfoRow(
                      label: 'Kembalian',
                      value: formatRupiah(result.changeAmount),
                    ),
                  ],
                  if (result.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Catatan transaksi: ${result.notes}'),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Terima kasih', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _shareReceipt(result, settings),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Bagikan struk'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali ke katalog'),
          ),
        ],
      ),
    );
  }
}
