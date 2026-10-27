import '../../domain/entities/balance.dart';

class BalanceAccountModel extends BalanceAccount {
  const BalanceAccountModel({
    required super.id,
    required super.paymentMethod,
    required super.balance,
  });

  factory BalanceAccountModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final method = json['payment_method'];
    final balance = json['balance'];
    if (id is! String || method is! String || balance is! num) {
      throw const FormatException('Data saldo dari server tidak valid.');
    }
    return BalanceAccountModel(
      id: id,
      paymentMethod: method,
      balance: balance,
    );
  }
}

class BalanceHistoryEntryModel extends BalanceHistoryEntry {
  const BalanceHistoryEntryModel({
    required super.id,
    required super.paymentMethod,
    required super.type,
    required super.amount,
    required super.finalBalance,
    required super.notes,
    required super.createdAt,
    super.createdBy,
    super.createdByEmail,
  });

  factory BalanceHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'];
    final method = json['payment_method'];
    final type = json['type'];
    final amount = json['amount'];
    final finalBalance = json['final_balance'];
    if (id is! String ||
        method is! String ||
        type is! String ||
        amount is! num ||
        finalBalance is! num) {
      throw const FormatException('Data riwayat saldo dari server tidak valid.');
    }
    final user = json['created_by'];
    final date = json['createdAt'] ?? json['created_at'];
    return BalanceHistoryEntryModel(
      id: id,
      paymentMethod: method,
      type: type,
      amount: amount,
      finalBalance: finalBalance,
      notes: json['notes'] is String ? json['notes'] as String : '',
      createdAt: date is String ? DateTime.tryParse(date) : null,
      createdBy: user is Map<String, dynamic> && user['name'] is String
          ? user['name'] as String
          : null,
      createdByEmail: user is Map<String, dynamic> && user['email'] is String
          ? user['email'] as String
          : null,
    );
  }
}
