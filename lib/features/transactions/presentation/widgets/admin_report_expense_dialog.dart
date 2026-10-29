part of '../pages/admin_transaction_report_page.dart';

class _RecordExpenseDialog extends StatefulWidget {
  const _RecordExpenseDialog({
    required this.paymentMethods,
    required this.repository,
  });

  final List<String> paymentMethods;
  final BalancesRepository repository;

  @override
  State<_RecordExpenseDialog> createState() => _RecordExpenseDialogState();
}

class _RecordExpenseDialogState extends State<_RecordExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late String _paymentMethod;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.paymentMethods.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Catat biaya operasional'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Keperluan biaya',
                hintText: 'Contoh: Belanja gas',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Keperluan biaya wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah biaya',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = num.tryParse(value ?? '');
                return amount == null || !amount.isFinite || amount <= 0
                    ? 'Masukkan jumlah biaya lebih dari 0.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Sumber pembayaran',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: widget.paymentMethods
                  .map(
                    (method) =>
                        DropdownMenuItem(value: method, child: Text(method)),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _paymentMethod = value);
                      }
                    },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Simpan biaya'),
      ),
    ],
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.recordExpense(
        paymentMethod: _paymentMethod,
        amount: num.parse(_amountController.text.trim()),
        notes: _notesController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Biaya gagal disimpan: $error';
      });
    }
  }
}
