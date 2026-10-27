class BalanceAccount {
  const BalanceAccount({
    required this.id,
    required this.paymentMethod,
    required this.balance,
  });

  final String id;
  final String paymentMethod;
  final num balance;
}

class BalanceHistoryEntry {
  const BalanceHistoryEntry({
    required this.id,
    required this.paymentMethod,
    required this.type,
    required this.amount,
    required this.finalBalance,
    required this.notes,
    required this.createdAt,
    this.createdBy,
    this.createdByEmail,
  });

  final String id;
  final String paymentMethod;
  final String type;
  final num amount;
  final num finalBalance;
  final String notes;
  final DateTime? createdAt;
  final String? createdBy;
  final String? createdByEmail;
}
