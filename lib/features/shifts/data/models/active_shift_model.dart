import '../../domain/entities/active_shift.dart';

class ActiveShiftModel extends ActiveShift {
  const ActiveShiftModel({
    required super.id,
    required super.status,
    required super.startTime,
    required super.startingCash,
    required super.expectedCash,
    required super.totalSales,
    required super.totalTransactions,
    super.outletName,
    super.outletId,
    super.endTime,
    super.actualCash,
    super.cashDifference,
    super.cashierName,
    super.cashierEmail,
    super.notes,
  });

  factory ActiveShiftModel.fromJson(Map<String, dynamic> json) {
    final outlet = json['outlet_id'];
    final user = json['user_id'];
    return ActiveShiftModel(
      id: _stringValue(json['_id'] ?? json['id'], '_id'),
      status: _stringValue(json['status'], 'status'),
      startTime: DateTime.parse(_stringValue(json['start_time'], 'start_time')),
      startingCash: _numberValue(json['starting_cash'], 'starting_cash'),
      expectedCash: _numberValue(json['expected_cash'], 'expected_cash'),
      totalSales: _numberValue(json['total_sales'], 'total_sales'),
      totalTransactions: _numberValue(
        json['total_transactions'] ?? 0,
        'total_transactions',
      ).toInt(),
      outletName: outlet is Map<String, dynamic>
          ? outlet['name'] as String?
          : null,
      outletId: outlet is Map<String, dynamic>
          ? _optionalString(outlet['_id'] ?? outlet['id'])
          : _optionalString(outlet),
      endTime: json['end_time'] is String
          ? DateTime.parse(json['end_time'] as String)
          : null,
      actualCash: json['actual_cash'] is num
          ? json['actual_cash'] as num
          : null,
      cashDifference: json['cash_difference'] is num
          ? json['cash_difference'] as num
          : null,
      cashierName: user is Map<String, dynamic> && user['name'] is String
          ? user['name'] as String
          : null,
      cashierEmail: user is Map<String, dynamic> && user['email'] is String
          ? user['email'] as String
          : null,
      notes: json['notes'] is String ? json['notes'] as String : '',
    );
  }

  static String _stringValue(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('Data shift tidak memiliki $field yang valid.');
  }

  static num _numberValue(Object? value, String field) {
    if (value is num) return value;
    throw FormatException('Data shift tidak memiliki $field yang valid.');
  }

  static String? _optionalString(Object? value) {
    return value is String ? value : null;
  }
}

class CashAvailabilityModel extends CashAvailability {
  const CashAvailabilityModel({
    required super.globalBalance,
    required super.reservedCash,
    required super.availableCash,
  });

  factory CashAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return CashAvailabilityModel(
      globalBalance: _numberValue(json['global_balance'], 'global_balance'),
      reservedCash: _numberValue(json['reserved_cash'], 'reserved_cash'),
      availableCash: _numberValue(json['available_cash'], 'available_cash'),
    );
  }

  static num _numberValue(Object? value, String field) {
    if (value is num) return value;
    throw FormatException(
      'Data ketersediaan kas tidak memiliki $field yang valid.',
    );
  }
}
