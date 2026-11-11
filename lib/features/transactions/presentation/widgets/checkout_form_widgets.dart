// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:kawula_pos/features/products/domain/entities/cart_item.dart';
import 'package:kawula_pos/features/products/presentation/bloc/cart_cubit.dart';
import 'package:kawula_pos/features/products/presentation/pages/product_formatters.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/presentation/bloc/checkout_cubit.dart';
import 'package:kawula_pos/features/transactions/presentation/pages/checkout_page.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/checkout_member_widgets.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/checkout_shared_widgets.dart';

extension CheckoutFormWidgets on CheckoutPageState {
  Widget checkoutForm(
    BuildContext context,
    List<CheckoutPaymentMethod> paymentMethods,
    CheckoutSettings settings, {
    required bool isSubmitting,
    required bool isOffline,
    String? errorMessage,
  }) {
    final cart = context.watch<CartCubit>().state;
    final taxAmount = (cart.estimatedSubtotal * settings.taxPercentage / 100)
        .round();
    final serviceCharge = serviceChargeEnabled ? settings.serviceCharge : 0;
    final totalAmount = (cart.estimatedSubtotal + taxAmount + serviceCharge)
        .round();
    final methods = paymentMethods
        .where((method) => !method.isOpenBill)
        .toList(growable: false);
    CheckoutPaymentMethod? selectedMethod;
    for (final method in methods) {
      if (method.code == selectedMethodCode) {
        selectedMethod = method;
        break;
      }
    }
    selectedMethod ??= methods.isEmpty ? null : methods.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.outletId == null || widget.outletId!.isEmpty)
          const CheckoutInlineError(
            message: 'ID outlet pada shift aktif tidak tersedia. Muat ulang shift sebelum membuat transaksi.',
          ),
        if (errorMessage != null) CheckoutInlineError(message: errorMessage),
        if (isOffline)
          const CheckoutInlineError(
            message: 'Mode offline: transaksi disimpan di perangkat dan belum tersinkron. Stok merupakan estimasi dari data terakhir.',
          ),
        if (validationMessage != null)
          CheckoutInlineError(message: validationMessage!),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ringkasan pesanan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: Text('${cart.totalQuantity} item'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in cart.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
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
                CheckoutAmountRow(
                  label: 'Subtotal estimasi',
                  amount: cart.estimatedSubtotal.round(),
                ),
                CheckoutAmountRow(
                  label: 'Pajak (${settings.taxPercentage}%)',
                  amount: taxAmount,
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Gunakan Biaya Layanan'),
                    secondary: Text(formatRupiah(settings.serviceCharge)),
                    value: serviceChargeEnabled,
                    onChanged: isSubmitting
                        ? null
                        : (value) => updateState(() {
                            serviceChargeEnabled = value ?? false;
                            validationMessage = null;
                          }),
                  ),
                ),
                CheckoutAmountRow(
                  label: 'Biaya layanan',
                  amount: serviceCharge,
                ),
                const Divider(height: 24),
                CheckoutAmountRow(
                  label: 'Total estimasi',
                  amount: totalAmount,
                  isEmphasized: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        memberSelector(context, isSubmitting),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: tableNumberController,
              enabled: !isSubmitting,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'No. Meja (opsional)',
                hintText: 'Contoh: A1 atau 12',
                prefixIcon: Icon(Icons.table_bar_outlined),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Metode pembayaran',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Simpan sebagai open bill'),
                  subtitle: const Text(
                    'Transaksi dibuat sebagai pending dan belum dianggap lunas.',
                  ),
                  value: openBill,
                  onChanged: isSubmitting
                      ? null
                      : (value) => updateState(() {
                          openBill = value;
                          validationMessage = null;
                        }),
                ),
                if (!openBill) ...[
                  const SizedBox(height: 12),
                  if (methods.isEmpty)
                    const CheckoutInlineError(
                      message: 'Tidak ada metode pembayaran aktif. Open bill masih dapat digunakan.',
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedMethod?.code,
                      decoration: const InputDecoration(
                        labelText: 'Pilih metode pembayaran',
                      ),
                      items: [
                        for (final method in methods)
                          DropdownMenuItem(
                            value: method.code,
                            child: Text(method.name),
                          ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) => updateState(() {
                              selectedMethodCode = value;
                              validationMessage = null;
                            }),
                    ),
                  if (isOffline && selectedMethod != null)
                    _offlinePaymentInstructions(selectedMethod),
                  if (selectedMethod?.isCash == true) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: cashController,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Uang diterima',
                        prefixText: 'Rp ',
                      ),
                      onChanged: (_) => updateState(() {}),
                    ),
                    const SizedBox(height: 8),
                    CheckoutAmountRow(
                      label: 'Kembalian estimasi',
                      amount: (_parseCashAmount() - totalAmount).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                  ],
                  if (methods.isNotEmpty && !isOffline) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
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
                        helperText:
                            'Masukkan PIN 4 digit untuk melunasi transaksi.',
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isOffline
                ? 'Transaksi offline dihitung dari harga dan pengaturan cache; stok hanya estimasi.'
                : 'Nilai final, pajak, dan biaya layanan akan dihitung ulang oleh server.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              isSubmitting ||
                  cart.isEmpty ||
                  widget.outletId == null ||
                  widget.outletId!.isEmpty ||
                  (!openBill && selectedMethod == null)
              ? null
              : () => _submit(
                  context,
                  selectedMethod,
                  totalAmount,
                  serviceCharge,
                  cart.items,
                  isOffline: isOffline,
                ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    openBill
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
    num serviceCharge,
    List<CartItem> items, {
    required bool isOffline,
  }) async {
    final openBill = this.openBill;
    final cashAmount = method?.isCash == true
        ? _parseCashAmount()
        : totalAmount;
    final pin = pinController.text.trim();
    if (!openBill && !isOffline && pin.length != 4) {
      updateState(() => validationMessage = 'PIN harus terdiri dari 4 digit.');
      return;
    }
    if (!openBill && method?.isCash == true && cashAmount < totalAmount) {
      updateState(
        () => validationMessage =
            'Uang diterima tidak boleh kurang dari total estimasi.',
      );
      return;
    }
    updateState(() => validationMessage = null);
    await context.read<CheckoutCubit>().submit(
      outletId: widget.outletId!,
      items: items,
      estimatedTotal: totalAmount,
      serviceCharge: serviceCharge,
      paymentMethod: method?.code ?? 'OPEN_BILL',
      paidAmount: cashAmount,
      pin: openBill || isOffline ? null : pin,
      openBill: openBill,
      memberId: selectedMember?.id,
      tableNumber: tableNumberController.text.trim(),
    );
  }

  num _parseCashAmount() => num.tryParse(cashController.text.trim()) ?? 0;

  Widget _offlinePaymentInstructions(CheckoutPaymentMethod method) {
    final descriptor = '${method.code} ${method.name}'.toUpperCase();
    final message = descriptor.contains('QRIS')
        ? 'Informasi QRIS toko tidak tersedia dalam data checkout yang tersimpan.'
        : descriptor.contains('TRANSFER') || descriptor.contains('BANK')
        ? 'Informasi rekening bank tidak tersedia dalam data checkout yang tersimpan.'
        : null;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
