// Flutter imports:
import 'package:flutter/material.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/transactions/presentation/widgets/open_bill_dialogs.dart';

class CatalogOpenBillsSection extends StatefulWidget {
  const CatalogOpenBillsSection({super.key, required this.checkoutRepository});

  final CheckoutRepository checkoutRepository;

  @override
  State<CatalogOpenBillsSection> createState() =>
      CatalogOpenBillsSectionState();
}

class CatalogOpenBillsSectionState extends State<CatalogOpenBillsSection> {
  List<TransactionRecord> _openBills = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final transactions = await widget.checkoutRepository.getTransactions();
      if (!mounted) return;
      setState(() {
        _openBills = transactions
            .where((transaction) => transaction.isPending)
            .toList(growable: false);
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showOpenBills() async {
    await reload();
    if (!mounted) return;
    if (_errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open bill gagal dimuat: $_errorMessage')),
      );
      return;
    }
    if (_openBills.isEmpty) return;

    final transaction = await showOpenBillsDialog(context, _openBills);
    if (transaction == null || !mounted) return;
    if (transaction.id.startsWith('OFF-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open Bill lokal belum dapat dilunasi, dibatalkan, atau diproses melalui server.',
          ),
        ),
      );
      return;
    }
    await _settleOpenBill(transaction);
  }

  Future<void> _settleOpenBill(TransactionRecord transaction) async {
    try {
      final methods = (await widget.checkoutRepository.getPaymentMethods())
          .where((method) => !method.isOpenBill)
          .toList(growable: false);
      if (!mounted) return;
      if (methods.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada metode pembayaran aktif.')),
        );
        return;
      }

      final input = await showOpenBillPaymentDialog(
        context,
        transaction: transaction,
        methods: methods,
      );
      if (input == null || !mounted) return;

      await widget.checkoutRepository.payPendingTransaction(
        transactionId: transaction.id,
        paymentMethod: input.paymentMethod,
        paidAmount: input.paidAmount,
        pin: input.pin,
      );
      await reload();
      if (!mounted) return;
      if (_errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran berhasil, tetapi daftar open bill gagal diperbarui: $_errorMessage',
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran open bill berhasil.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pembayaran gagal: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => CatalogOpenBillsPanel(
    billCount: _openBills.length,
    isLoading: _isLoading,
    errorMessage: _errorMessage,
    onRetry: reload,
    onViewBills: _showOpenBills,
  );
}

class CatalogOpenBillsPanel extends StatelessWidget {
  const CatalogOpenBillsPanel({
    super.key,
    required this.billCount,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onViewBills,
  });

  final int billCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onViewBills;

  @override
  Widget build(BuildContext context) {
    if (billCount == 0 && errorMessage == null) {
      return const SizedBox.shrink();
    }

    final hasError = errorMessage != null;
    final foreground = hasError
        ? Theme.of(context).colorScheme.error
        : const Color(0xFFB45309);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasError
            ? Theme.of(context).colorScheme.errorContainer
            : const Color(0xFFFFFBEB),
        border: Border.all(
          color: hasError
              ? Theme.of(context).colorScheme.error.withValues(alpha: .35)
              : const Color(0xFFFBBF24),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.schedule_outlined,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError
                      ? 'Open Bill tidak dapat dimuat'
                      : 'Open Bill ($billCount)',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hasError
                      ? errorMessage!
                      : 'Ada tagihan tertunda yang belum dilunasi',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isLoading
                ? null
                : hasError
                ? onRetry
                : onViewBills,
            style: TextButton.styleFrom(
              foregroundColor: foreground,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              isLoading
                  ? 'Memuat...'
                  : hasError
                  ? 'Coba Lagi'
                  : 'Lihat Tagihan',
            ),
          ),
        ],
      ),
    );
  }
}
