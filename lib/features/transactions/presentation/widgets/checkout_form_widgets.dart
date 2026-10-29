part of '../pages/checkout_page.dart';

// Extensions keep checkout rendering close to its page-owned state.
// ignore_for_file: invalid_use_of_protected_member

extension _CheckoutFormWidgets on _CheckoutPageState {
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
                _AmountRow(
                  label: 'Subtotal estimasi',
                  amount: cart.estimatedSubtotal.round(),
                ),
                _AmountRow(
                  label: 'Pajak (${settings.taxPercentage}%)',
                  amount: taxAmount,
                ),
                _AmountRow(
                  label: 'Biaya layanan',
                  amount: settings.serviceCharge,
                ),
                const Divider(height: 24),
                _AmountRow(
                  label: 'Total estimasi',
                  amount: totalAmount,
                  isEmphasized: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _memberSelector(context, isSubmitting),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _tableNumberController,
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
                  if (methods.isNotEmpty) ...[
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
            'Nilai final, pajak, dan biaya layanan akan dihitung ulang oleh server.',
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
      memberId: _selectedMember?.id,
      tableNumber: _tableNumberController.text.trim(),
    );
  }

  num _parseCashAmount() => num.tryParse(_cashController.text.trim()) ?? 0;
}
