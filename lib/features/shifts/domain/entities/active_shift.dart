class ActiveShift {
  const ActiveShift({
    required this.id,
    required this.status,
    required this.startTime,
    required this.startingCash,
    required this.expectedCash,
    required this.totalSales,
    required this.totalTransactions,
    this.outletName,
    this.outletId,
    this.endTime,
    this.actualCash,
    this.cashDifference,
    this.cashierName,
    this.cashierEmail,
    this.notes = '',
  });

  final String id;
  final String status;
  final DateTime startTime;
  final num startingCash;
  final num expectedCash;
  final num totalSales;
  final int totalTransactions;
  final String? outletName;
  final String? outletId;
  final DateTime? endTime;
  final num? actualCash;
  final num? cashDifference;
  final String? cashierName;
  final String? cashierEmail;
  final String notes;
}

class CashAvailability {
  const CashAvailability({
    required this.globalBalance,
    required this.reservedCash,
    required this.availableCash,
  });

  final num globalBalance;
  final num reservedCash;
  final num availableCash;
}
