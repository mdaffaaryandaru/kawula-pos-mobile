import '../../../transactions/domain/entities/checkout.dart';
import 'active_shift.dart';

class AdminShiftDetail {
  const AdminShiftDetail({required this.shift, required this.transactions});

  final ActiveShift shift;
  final List<TransactionRecord> transactions;
}
