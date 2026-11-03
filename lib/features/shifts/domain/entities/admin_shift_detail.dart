// Project imports:
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/transactions/domain/entities/checkout.dart';

class AdminShiftDetail {
  const AdminShiftDetail({required this.shift, required this.transactions});

  final ActiveShift shift;
  final List<TransactionRecord> transactions;
}
