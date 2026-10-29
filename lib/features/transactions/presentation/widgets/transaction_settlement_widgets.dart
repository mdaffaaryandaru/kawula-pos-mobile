part of '../pages/transactions_history_page.dart';

class _SettlementInput {
  const _SettlementInput({
    required this.paymentMethod,
    required this.paidAmount,
    required this.pin,
  });

  final String paymentMethod;
  final num paidAmount;
  final String pin;
}

class _SettlementDialog extends StatefulWidget {
  const _SettlementDialog({required this.transaction, required this.methods});

  final TransactionRecord transaction;
  final List<CheckoutPaymentMethod> methods;

  @override
  State<_SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<_SettlementDialog> {
  final _cashController = TextEditingController();
  final _pinController = TextEditingController();
  String? _selectedCode;
  String? _errorMessage;

  @override
  void dispose() {
    _cashController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final method = _findMethod(widget.methods, _selectedCode);
    return AlertDialog(
      title: const Text('Lunasi open bill'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total transaksi: ${formatRupiah(widget.transaction.totalAmount)}',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: method.code,
              decoration: const InputDecoration(labelText: 'Metode pembayaran'),
              items: [
                for (final paymentMethod in widget.methods)
                  DropdownMenuItem(
                    value: paymentMethod.code,
                    child: Text(paymentMethod.name),
                  ),
              ],
              onChanged: (value) => setState(() {
                _selectedCode = value;
                _errorMessage = null;
              }),
            ),
            if (method.isCash) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Uang diterima',
                  prefixText: 'Rp ',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'PIN kasir'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final pin = _pinController.text.trim();
            final paidAmount = method.isCash
                ? num.tryParse(_cashController.text.trim()) ?? 0
                : widget.transaction.totalAmount;
            if (pin.length != 4) {
              setState(() => _errorMessage = 'PIN harus terdiri dari 4 digit.');
              return;
            }
            if (method.isCash && paidAmount < widget.transaction.totalAmount) {
              setState(
                () => _errorMessage =
                    'Uang diterima kurang dari total transaksi.',
              );
              return;
            }
            Navigator.pop(
              context,
              _SettlementInput(
                paymentMethod: method.code,
                paidAmount: paidAmount,
                pin: pin,
              ),
            );
          },
          child: const Text('Konfirmasi pelunasan'),
        ),
      ],
    );
  }
}

CheckoutPaymentMethod _findMethod(
  List<CheckoutPaymentMethod> methods,
  String? selectedCode,
) {
  for (final method in methods) {
    if (method.code == selectedCode) return method;
  }
  return methods.first;
}
