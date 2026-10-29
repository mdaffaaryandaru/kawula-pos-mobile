part of '../pages/checkout_page.dart';

extension _CheckoutReceiptActions on _CheckoutPageState {
  Future<void> _shareReceipt(
    CheckoutResult result,
    CheckoutSettings settings,
  ) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: result.status.toLowerCase() == 'pending'
              ? 'Open bill ${result.id}'
              : 'Struk transaksi ${result.id}',
          text: _receiptText(result, settings),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Struk tidak dapat dibagikan: $error')),
      );
    }
  }

  String _receiptText(CheckoutResult result, CheckoutSettings settings) {
    final isPending = result.status.toLowerCase() == 'pending';
    final lines = <String>[
      if (settings.storeName.isNotEmpty) settings.storeName,
      if (settings.address.isNotEmpty) settings.address,
      '',
      isPending ? 'OPEN BILL - BELUM LUNAS' : 'STRUK PEMBAYARAN',
      'No. transaksi: ${result.id}',
      'Waktu: ${result.createdAt == null ? 'Tidak tersedia' : _formatReceiptDate(result.createdAt!)}',
      if (_selectedMember case final member?)
        'Member: ${member.name} (${member.phoneNumber})',
      if (_tableNumberController.text.trim().isNotEmpty)
        'No. meja: ${_tableNumberController.text.trim()}',
      '',
      for (final item in result.items) ...[
        '${item.quantity} x ${item.productName} - ${formatRupiah(item.price * item.quantity)}',
        for (final variant in item.selectedVariants)
          '  ${variant.groupName}: ${variant.optionName}',
        if (item.notes.isNotEmpty) '  Catatan: ${item.notes}',
      ],
      if (result.subtotal != null)
        'Subtotal: ${formatRupiah(result.subtotal!)}',
      if (result.taxAmount != null) 'Pajak: ${formatRupiah(result.taxAmount!)}',
      if (result.serviceCharge != null)
        'Biaya layanan: ${formatRupiah(result.serviceCharge!)}',
      if (result.discountAmount != null && result.discountAmount! > 0)
        'Diskon: -${formatRupiah(result.discountAmount!)}',
      'TOTAL: ${formatRupiah(result.totalAmount)}',
      'Metode: ${result.paymentMethod}',
      if (isPending)
        'Status: Belum lunas'
      else ...[
        'Dibayar: ${formatRupiah(result.paidAmount)}',
        'Kembalian: ${formatRupiah(result.changeAmount)}',
      ],
      if (result.notes.isNotEmpty) 'Catatan transaksi: ${result.notes}',
      '',
      'Terima kasih',
    ];
    return lines.join('\n');
  }

  String _formatReceiptDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}
