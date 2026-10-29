import 'package:flutter/material.dart';

import '../../../transactions/domain/entities/checkout.dart';
import '../../domain/entities/balance.dart';

class BalanceEditDialog extends StatefulWidget {
  const BalanceEditDialog({
    super.key,
    required this.methods,
    required this.balances,
    required this.initialMethod,
    required this.isExpense,
  });

  final List<CheckoutPaymentMethod> methods;
  final List<BalanceAccount> balances;
  final String initialMethod;
  final bool isExpense;

  @override
  State<BalanceEditDialog> createState() => _BalanceEditDialogState();
}

class _BalanceEditDialogState extends State<BalanceEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late String _paymentMethod;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.initialMethod;
    if (!widget.isExpense) {
      _amountController.text = _balanceFor(_paymentMethod)?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  num? _balanceFor(String paymentMethod) => widget.balances
      .where(
        (item) =>
            item.paymentMethod.toUpperCase() == paymentMethod.toUpperCase(),
      )
      .firstOrNull
      ?.balance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isExpense ? 'Catat pengeluaran' : 'Sesuaikan saldo'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Metode pembayaran',
                ),
                items: widget.methods
                    .map(
                      (method) => DropdownMenuItem(
                        value: method.code,
                        child: Text(method.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _paymentMethod = value;
                    if (!widget.isExpense) {
                      _amountController.text =
                          _balanceFor(value)?.toString() ?? '0';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: widget.isExpense
                      ? 'Nominal pengeluaran'
                      : 'Saldo aktual',
                  prefixText: 'Rp ',
                  helperText: widget.isExpense
                      ? 'Nominal ini akan mengurangi saldo metode yang dipilih.'
                      : 'Masukkan saldo hasil hitung fisik, bukan selisihnya.',
                ),
                validator: (value) {
                  final amount = num.tryParse(value ?? '');
                  if (amount == null || !amount.isFinite || amount < 0) {
                    return 'Masukkan nominal yang valid.';
                  }
                  if (widget.isExpense && amount == 0) {
                    return 'Pengeluaran harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Catatan'),
                maxLines: 2,
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Catatan wajib diisi.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      BalanceDraft(
        paymentMethod: _paymentMethod,
        amount: num.parse(_amountController.text),
        notes: _notesController.text.trim(),
      ),
    );
  }
}

class BalanceDraft {
  const BalanceDraft({
    required this.paymentMethod,
    required this.amount,
    required this.notes,
  });

  final String paymentMethod;
  final num amount;
  final String notes;
}
