import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../products/presentation/bloc/cart_cubit.dart';
import '../../../products/presentation/pages/product_formatters.dart';
import '../../domain/entities/checkout.dart';
import '../bloc/checkout_cubit.dart';
import '../bloc/checkout_state.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.outletId});

  final String? outletId;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _cashController = TextEditingController();
  final _pinController = TextEditingController();
  String? _selectedMethodCode;
  bool _openBill = false;
  String? _validationMessage;

  @override
  void dispose() {
    _cashController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutCompleted) {
          context.read<CartCubit>().clear();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Pembayaran')),
          body: switch (state) {
            CheckoutLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            CheckoutFailure() => _failure(context, state.message),
            CheckoutCompleted() => _completed(state.result, state.settings),
            CheckoutReady() => _checkoutForm(
              context,
              state.paymentMethods,
              state.settings,
              isSubmitting: false,
              errorMessage: state.errorMessage,
            ),
            CheckoutSubmitting() => _checkoutForm(
              context,
              state.paymentMethods,
              state.settings,
              isSubmitting: true,
            ),
          },
        );
      },
    );
  }

  Widget _checkoutForm(
    BuildContext context,
    List<CheckoutPaymentMethod> paymentMethods,
    CheckoutSettings settings, {
    required bool isSubmitting,
    String? errorMessage,
  }) {
    final cart = context.watch<CartCubit>().state;
    final taxAmount = (cart.estimatedSubtotal * settings.taxPercentage / 100)
        .round();
    final totalAmount =
        (cart.estimatedSubtotal + taxAmount + settings.serviceCharge).round();
    final methods = paymentMethods
        .where((method) => !method.isOpenBill)
        .toList(growable: false);
    CheckoutPaymentMethod? selectedMethod;
    for (final method in methods) {
      if (method.code == _selectedMethodCode) {
        selectedMethod = method;
        break;
      }
    }
    selectedMethod ??= methods.isEmpty ? null : methods.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.outletId == null || widget.outletId!.isEmpty)
          const _InlineError(
            message: 'ID outlet pada shift aktif tidak tersedia. Muat ulang shift sebelum membuat transaksi.',
          ),
        if (errorMessage != null) _InlineError(message: errorMessage),
        if (_validationMessage != null)
          _InlineError(message: _validationMessage!),
        Text(
          'Ringkasan pesanan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final item in cart.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity} × ${item.product.name}'
                    '${item.selectedVariants.isEmpty ? '' : ' (${item.selectedVariants.map((variant) => variant.optionName).join(', ')})'}'
                    '${item.notes.isEmpty ? '' : '\nCatatan: ${item.notes}'}',
                  ),
                ),
                const SizedBox(width: 12),
                Text(formatRupiah(item.unitPrice * item.quantity)),
              ],
            ),
          ),
        const Divider(height: 28),
        _AmountRow(
          label: 'Subtotal estimasi',
          amount: cart.estimatedSubtotal.round(),
        ),
        _AmountRow(
          label: 'Pajak (${settings.taxPercentage}%)',
          amount: taxAmount,
        ),
        _AmountRow(label: 'Biaya layanan', amount: settings.serviceCharge),
        const Divider(height: 24),
        _AmountRow(
          label: 'Total estimasi',
          amount: totalAmount,
          isEmphasized: true,
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Simpan sebagai open bill'),
          subtitle: const Text(
            'Transaksi dibuat sebagai pending dan belum dianggap lunas.',
          ),
          value: _openBill,
          onChanged: isSubmitting
              ? null
              : (value) => setState(() {
                  _openBill = value;
                  _validationMessage = null;
                }),
        ),
        if (!_openBill) ...[
          const SizedBox(height: 12),
          if (methods.isEmpty)
            const _InlineError(
              message: 'Tidak ada metode pembayaran aktif. Open bill masih dapat digunakan.',
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedMethod?.code,
              decoration: const InputDecoration(labelText: 'Metode pembayaran'),
              items: [
                for (final method in methods)
                  DropdownMenuItem(
                    value: method.code,
                    child: Text(method.name),
                  ),
              ],
              onChanged: isSubmitting
                  ? null
                  : (value) => setState(() {
                      _selectedMethodCode = value;
                      _validationMessage = null;
                    }),
            ),
          if (selectedMethod?.isCash == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _cashController,
              enabled: !isSubmitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Uang diterima',
                prefixText: 'Rp ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            _AmountRow(
              label: 'Kembalian estimasi',
              amount: (_parseCashAmount() - totalAmount).clamp(
                0,
                double.infinity,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            enabled: !isSubmitting,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(
              labelText: 'PIN kasir',
              helperText: 'Masukkan PIN 4 digit untuk melunasi transaksi.',
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Nilai final, pajak, dan biaya layanan akan dihitung ulang oleh server.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              isSubmitting ||
                  cart.isEmpty ||
                  widget.outletId == null ||
                  widget.outletId!.isEmpty ||
                  (!_openBill && selectedMethod == null)
              ? null
              : () => _submit(context, selectedMethod, totalAmount, cart.items),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _openBill
                        ? 'Buat open bill'
                        : 'Bayar ${formatRupiah(totalAmount)}',
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(
    BuildContext context,
    CheckoutPaymentMethod? method,
    num totalAmount,
    List<CartItem> items,
  ) async {
    final openBill = _openBill;
    final cashAmount = method?.isCash == true
        ? _parseCashAmount()
        : totalAmount;
    final pin = _pinController.text.trim();
    if (!openBill && pin.length != 4) {
      setState(() => _validationMessage = 'PIN harus terdiri dari 4 digit.');
      return;
    }
    if (!openBill && method?.isCash == true && cashAmount < totalAmount) {
      setState(
        () => _validationMessage =
            'Uang diterima tidak boleh kurang dari total estimasi.',
      );
      return;
    }
    setState(() => _validationMessage = null);
    await context.read<CheckoutCubit>().submit(
      outletId: widget.outletId!,
      items: items,
      estimatedTotal: totalAmount,
      paymentMethod: method?.code ?? 'OPEN_BILL',
      paidAmount: cashAmount,
      pin: openBill ? null : pin,
      openBill: openBill,
    );
  }

  num _parseCashAmount() => num.tryParse(_cashController.text.trim()) ?? 0;

  Widget _failure(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Checkout belum dapat dimuat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: context.read<CheckoutCubit>().load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completed(CheckoutResult result, CheckoutSettings settings) {
    final isPending = result.status.toLowerCase() == 'pending';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isPending ? 'Open bill berhasil dibuat' : 'Pembayaran berhasil',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

class _ReceiptInfoRow extends StatelessWidget {
  const _ReceiptInfoRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.isEmphasized = false,
  });

  final String label;
  final num amount;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final style = isEmphasized
        ? Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              formatRupiah(amount),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
