import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/discounts/domain/repositories/discounts_repository.dart';
import 'package:kawula_pos/features/inventories/domain/repositories/inventory_repository.dart';
import 'package:kawula_pos/features/members/domain/repositories/members_repository.dart';
import 'package:kawula_pos/features/membership_programs/domain/repositories/membership_programs_repository.dart';
import 'package:kawula_pos/features/outlets/domain/repositories/outlets_repository.dart';
import 'package:kawula_pos/features/payment_method/domain/repositories/payment_methods_repository.dart';
import 'package:kawula_pos/features/product_units/domain/repositories/product_units_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/product_management_repository.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/table_areas/domain/repositories/table_areas_repository.dart';
import 'package:kawula_pos/features/tables/domain/repositories/tables_repository.dart';
import 'package:kawula_pos/features/transactions/domain/services/offline_transaction_reconciliation.dart';
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/variant_groups/domain/repositories/variant_groups_repository.dart';

class AdminDependencies {
  const AdminDependencies({
    required this.apiBaseUrl,
    required this.catalogRepository,
    required this.offlineTransactionReconciliation,
    required this.storeSettingsRepository,
    required this.userManagementRepository,
    required this.productManagementRepository,
    required this.categoriesRepository,
    required this.variantGroupsRepository,
    this.discountsRepository,
    this.paymentMethodsRepository,
    this.inventoryRepository,
    this.productUnitsRepository,
    this.outletsRepository,
    this.tableAreasRepository,
    this.tablesRepository,
    this.membersRepository,
    this.membershipProgramsRepository,
  });

  final String apiBaseUrl;
  final CatalogRepository catalogRepository;
  final OfflineTransactionReconciliation offlineTransactionReconciliation;
  final StoreSettingsRepository storeSettingsRepository;
  final UserManagementRepository userManagementRepository;
  final ProductManagementRepository productManagementRepository;
  final CategoriesRepository categoriesRepository;
  final VariantGroupsRepository variantGroupsRepository;
  final DiscountsRepository? discountsRepository;
  final PaymentMethodsRepository? paymentMethodsRepository;
  final InventoryRepository? inventoryRepository;
  final ProductUnitsRepository? productUnitsRepository;
  final OutletsRepository? outletsRepository;
  final TableAreasRepository? tableAreasRepository;
  final TablesRepository? tablesRepository;
  final MembersRepository? membersRepository;
  final MembershipProgramsRepository? membershipProgramsRepository;
}
