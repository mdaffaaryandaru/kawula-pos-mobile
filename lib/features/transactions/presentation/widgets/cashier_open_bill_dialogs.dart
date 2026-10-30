import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';
import '../../../products/presentation/pages/product_formatters.dart';
import '../../domain/entities/checkout.dart';

Future<TransactionRecord?> showCashierOpenBillsDialog(
  BuildContext context,
  List<TransactionRecord> transactions,
) {
  return showDialog<TransactionRecord>(
    context: context,
    builder: (_) => _OpenBillsDialog(transactions: transactions),
  );
}

Future<CashierOpenBillPaymentInput?> showCashierOpenBillPaymentDialog(
  BuildContext context, {
  required TransactionRecord transaction,
  required List<CheckoutPaymentMethod> methods,
}) {
  return showDialog<CashierOpenBillPaymentInput>(
    context: context,
    builder: (_) =>
        _OpenBillPaymentDialog(transaction: transaction, methods: methods),
  );
}

class CashierOpenBillPaymentInput {
  const CashierOpenBillPaymentInput({
    required this.paymentMethod,
    required this.paidAmount,
    required this.pin,
  });

  final String paymentMethod;
  final num paidAmount;
  final String pin;
}

class _OpenBillsDialog extends StatelessWidget {
  const _OpenBillsDialog({required this.transactions});

  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: size.height * .78,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Daftar Open Bill',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final itemCount = transaction.items.fold<int>(
                    0,
                    (total, item) => total + item.quantity,
                  );
                  return Material(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(transaction),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFFBBF24)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.cashierName.isEmpty
                                        ? 'Kasir'
                                        : transaction.cashierName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(transaction.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatRupiah(transaction.totalAmount),
                                  style: const TextStyle(
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '$itemCount item',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Waktu tidak tersedia';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$day/$month/${local.year}, $hour:$minute:$second';
  }
}

class _OpenBillPaymentDialog extends StatefulWidget {
  const _OpenBillPaymentDialog({
    required this.transaction,
    required this.methods,
  });

  final TransactionRecord transaction;
  final List<CheckoutPaymentMethod> methods;

  @override
  State<_OpenBillPaymentDialog> createState() => _OpenBillPaymentDialogState();
}

class _OpenBillPaymentDialogState extends State<_OpenBillPaymentDialog> {
  late final TextEditingController _cashController;
  final _pinController = TextEditingController();
  late String _selectedCode;
  String? _errorMessage;

  CheckoutPaymentMethod get _selectedMethod =>
      widget.methods.firstWhere((method) => method.code == _selectedCode);

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(
      text: widget.transaction.totalAmount.ceil().toString(),
    );
    _selectedCode = widget.methods.first.code;
  }

  @override
  void dispose() {
    _cashController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * .92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Proses Pembayaran',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Total Tagihan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(widget.transaction.totalAmount),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.methods.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.4,
                          ),
                      itemBuilder: (context, index) {
                        final method = widget.methods[index];
                        final selected = method.code == _selectedCode;
                        return Material(
                          color: selected
                              ? const Color(0xFFF5F8FF)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() {
                              _selectedCode = method.code;
                              _errorMessage = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      method.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_selectedMethod.isCash) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Uang Diterima (Rp)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(prefixText: 'Rp '),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Otorisasi PIN (4 Digit)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '••••',
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text(
                        'Selesaikan Pembayaran',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final pin = _pinController.text.trim();
    final paidAmount = _selectedMethod.isCash
        ? num.tryParse(_cashController.text.trim()) ?? 0
        : widget.transaction.totalAmount;
    if (pin.length != 4) {
      setState(() => _errorMessage = 'PIN harus terdiri dari 4 digit.');
      return;
    }
    if (_selectedMethod.isCash && paidAmount < widget.transaction.totalAmount) {
      setState(
        () => _errorMessage = 'Uang diterima kurang dari total tagihan.',
      );
      return;
    }
    Navigator.of(context).pop(
      CashierOpenBillPaymentInput(
        paymentMethod: _selectedMethod.code,
        paidAmount: paidAmount,
        pin: pin,
      ),
    );
  }
}
