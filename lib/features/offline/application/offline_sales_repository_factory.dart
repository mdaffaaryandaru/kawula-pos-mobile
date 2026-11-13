import 'package:kawula_pos/features/auth/domain/entities/auth_user.dart';
import 'package:kawula_pos/features/offline/domain/services/offline_network_status_controller.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/shifts/domain/entities/active_shift.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';

class OfflineSalesRepositoryScope {
  const OfflineSalesRepositoryScope({
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.networkStatus,
  });

  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final OfflineNetworkStatusController? networkStatus;
}

abstract interface class OfflineSalesRepositoryFactory {
  ShiftsRepository shiftsRepositoryFor(AuthUser user);

  OfflineSalesRepositoryScope createScope({
    required AuthUser user,
    required ActiveShift shift,
  });
}
