// Package imports:
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// Project imports:
import 'package:kawula_pos/config/api_config.dart';
import 'package:kawula_pos/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kawula_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kawula_pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kawula_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:kawula_pos/features/balances/data/datasources/balances_remote_data_source.dart';
import 'package:kawula_pos/features/balances/data/repositories/balances_repository_impl.dart';
import 'package:kawula_pos/features/balances/domain/repositories/balances_repository.dart';
import 'package:kawula_pos/features/categories/data/datasources/categories_remote_data_source.dart';
import 'package:kawula_pos/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:kawula_pos/features/categories/domain/repositories/categories_repository.dart';
import 'package:kawula_pos/features/discounts/data/datasources/discounts_remote_data_source.dart';
import 'package:kawula_pos/features/discounts/data/repositories/discounts_repository_impl.dart';
import 'package:kawula_pos/features/discounts/domain/repositories/discounts_repository.dart';
import 'package:kawula_pos/features/inventories/data/datasources/inventory_remote_data_source.dart';
import 'package:kawula_pos/features/inventories/data/repositories/inventory_repository_impl.dart';
import 'package:kawula_pos/features/inventories/domain/repositories/inventory_repository.dart';
import 'package:kawula_pos/features/members/data/datasources/members_remote_data_source.dart';
import 'package:kawula_pos/features/members/data/repositories/members_repository_impl.dart';
import 'package:kawula_pos/features/members/domain/repositories/members_repository.dart';
import 'package:kawula_pos/features/membership_programs/data/datasources/membership_programs_remote_data_source.dart';
import 'package:kawula_pos/features/membership_programs/data/repositories/membership_programs_repository_impl.dart';
import 'package:kawula_pos/features/membership_programs/domain/repositories/membership_programs_repository.dart';
import 'package:kawula_pos/features/outlets/data/datasources/outlets_remote_data_source.dart';
import 'package:kawula_pos/features/outlets/data/repositories/outlets_repository_impl.dart';
import 'package:kawula_pos/features/outlets/domain/repositories/outlets_repository.dart';
import 'package:kawula_pos/features/payment_method/data/datasources/payment_methods_remote_data_source.dart';
import 'package:kawula_pos/features/payment_method/data/repositories/payment_methods_repository_impl.dart';
import 'package:kawula_pos/features/payment_method/domain/repositories/payment_methods_repository.dart';
import 'package:kawula_pos/features/product_units/data/datasources/product_units_remote_data_source.dart';
import 'package:kawula_pos/features/product_units/data/repositories/product_units_repository_impl.dart';
import 'package:kawula_pos/features/product_units/domain/repositories/product_units_repository.dart';
import 'package:kawula_pos/features/products/data/datasources/catalog_remote_data_source.dart';
import 'package:kawula_pos/features/products/data/datasources/product_management_remote_data_source.dart';
import 'package:kawula_pos/features/products/data/repositories/catalog_repository_impl.dart';
import 'package:kawula_pos/features/products/data/repositories/product_management_repository_impl.dart';
import 'package:kawula_pos/features/products/domain/repositories/catalog_repository.dart';
import 'package:kawula_pos/features/products/domain/repositories/product_management_repository.dart';
import 'package:kawula_pos/features/shifts/data/datasources/shifts_remote_data_source.dart';
import 'package:kawula_pos/features/shifts/data/repositories/shifts_repository_impl.dart';
import 'package:kawula_pos/features/shifts/domain/repositories/shifts_repository.dart';
import 'package:kawula_pos/features/store_settings/data/datasources/store_settings_remote_data_source.dart';
import 'package:kawula_pos/features/store_settings/data/repositories/store_settings_repository_impl.dart';
import 'package:kawula_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:kawula_pos/features/table_areas/data/datasources/table_areas_remote_data_source.dart';
import 'package:kawula_pos/features/table_areas/data/repositories/table_areas_repository_impl.dart';
import 'package:kawula_pos/features/table_areas/domain/repositories/table_areas_repository.dart';
import 'package:kawula_pos/features/tables/data/datasources/tables_remote_data_source.dart';
import 'package:kawula_pos/features/tables/data/repositories/tables_repository_impl.dart';
import 'package:kawula_pos/features/tables/domain/repositories/tables_repository.dart';
import 'package:kawula_pos/features/transactions/data/datasources/checkout_remote_data_source.dart';
import 'package:kawula_pos/features/transactions/data/repositories/checkout_repository_impl.dart';
import 'package:kawula_pos/features/transactions/domain/repositories/checkout_repository.dart';
import 'package:kawula_pos/features/users/data/datasources/users_remote_data_source.dart';
import 'package:kawula_pos/features/users/data/repositories/user_management_repository_impl.dart';
import 'package:kawula_pos/features/users/domain/repositories/user_management_repository.dart';
import 'package:kawula_pos/features/variant_groups/data/datasources/variant_groups_remote_data_source.dart';
import 'package:kawula_pos/features/variant_groups/data/repositories/variant_groups_repository_impl.dart';
import 'package:kawula_pos/features/variant_groups/domain/repositories/variant_groups_repository.dart';
import 'package:kawula_pos/framework/core/network/auth_session_expiry_handler.dart';
import 'package:kawula_pos/framework/core/network/session_aware_http_client.dart';
import 'package:kawula_pos/framework/core/offline/database/app_database.dart';
import 'package:kawula_pos/framework/core/offline/cashier_master_data_cache.dart';

class AppDependencies {
  const AppDependencies({
    required this.apiBaseUrl,
    this.database,
    this.masterDataCache,
    required this.authRepository,
    this.sessionExpiryHandler,
    required this.shiftsRepository,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.balancesRepository,
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

  factory AppDependencies.create() {
    final sessionExpiryHandler = AuthSessionExpiryHandler();
    final client = SessionAwareHttpClient(http.Client(), sessionExpiryHandler);
    final apiBaseUrl = ApiConfig.baseUrl;
    final database = AppDatabase();
    final masterDataCache = CashierMasterDataCache(database.cachedRecordsDao);
    final remoteDataSource = AuthRemoteDataSource(client, apiBaseUrl);
    final localDataSource = AuthLocalDataSource(const FlutterSecureStorage());
    final authRepository = AuthRepositoryImpl(
      remoteDataSource,
      localDataSource,
      sessionExpiryHandler: sessionExpiryHandler,
    );
    final catalogRepository = CatalogRepositoryImpl(
      CatalogRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final shiftsRepository = ShiftsRepositoryImpl(
      ShiftsRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final membersRemoteDataSource = MembersRemoteDataSource(
      client,
      apiBaseUrl,
      localDataSource.readToken,
    );
    final membersRepository = MembersRepositoryImpl(membersRemoteDataSource);
    final membershipProgramsRepository = MembershipProgramsRepositoryImpl(
      MembershipProgramsRemoteDataSource(
        client,
        apiBaseUrl,
        localDataSource.readToken,
      ),
    );
    final checkoutRepository = CheckoutRepositoryImpl(
      CheckoutRemoteDataSource(
        client,
        apiBaseUrl,
        localDataSource.readToken,
        membersRemoteDataSource: membersRemoteDataSource,
      ),
    );
    final balancesRepository = BalancesRepositoryImpl(
      BalancesRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final storeSettingsRepository = StoreSettingsRepositoryImpl(
      StoreSettingsRemoteDataSource(
        client,
        apiBaseUrl,
        localDataSource.readToken,
      ),
      cacheDao: database.cachedRecordsDao,
    );
    final userManagementRepository = UserManagementRepositoryImpl(
      UsersRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final categoriesRepository = CategoriesRepositoryImpl(
      CategoriesRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final discountsRepository = DiscountsRepositoryImpl(
      DiscountsRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final paymentMethodsRepository = PaymentMethodsRepositoryImpl(
      PaymentMethodsRemoteDataSource(
        client,
        apiBaseUrl,
        localDataSource.readToken,
      ),
    );
    final inventoryRepository = InventoryRepositoryImpl(
      InventoryRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final productUnitsRepository = ProductUnitsRepositoryImpl(
      ProductUnitsRemoteDataSource(
        client,
        apiBaseUrl,
        localDataSource.readToken,
      ),
    );
    final variantGroupsRepository = VariantGroupsRepositoryImpl(
      VariantGroupsRemoteDataSource(
        client,
        apiBaseUrl,
        localDataSource.readToken,
      ),
      productUnitsRepository,
    );
    final productManagementRepository = ProductManagementRepositoryImpl(
      ProductManagementRemoteDataSource(
        client,
        apiBaseUrl,
        localDataSource.readToken,
      ),
      categoriesRepository,
      variantGroupsRepository,
      inventoryRepository,
      productUnitsRepository,
    );
    final outletsRepository = OutletsRepositoryImpl(
      OutletsRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final tableAreasRepository = TableAreasRepositoryImpl(
      TableAreasRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );
    final tablesRepository = TablesRepositoryImpl(
      TablesRemoteDataSource(client, apiBaseUrl, localDataSource.readToken),
    );

    return AppDependencies(
      apiBaseUrl: apiBaseUrl,
      database: database,
      masterDataCache: masterDataCache,
      authRepository: authRepository,
      sessionExpiryHandler: sessionExpiryHandler,
      shiftsRepository: shiftsRepository,
      catalogRepository: catalogRepository,
      checkoutRepository: checkoutRepository,
      balancesRepository: balancesRepository,
      storeSettingsRepository: storeSettingsRepository,
      userManagementRepository: userManagementRepository,
      productManagementRepository: productManagementRepository,
      categoriesRepository: categoriesRepository,
      discountsRepository: discountsRepository,
      paymentMethodsRepository: paymentMethodsRepository,
      variantGroupsRepository: variantGroupsRepository,
      inventoryRepository: inventoryRepository,
      productUnitsRepository: productUnitsRepository,
      outletsRepository: outletsRepository,
      tableAreasRepository: tableAreasRepository,
      tablesRepository: tablesRepository,
      membersRepository: membersRepository,
      membershipProgramsRepository: membershipProgramsRepository,
    );
  }

  final String apiBaseUrl;
  final AppDatabase? database;
  final CashierMasterDataCache? masterDataCache;
  final AuthRepository authRepository;
  final AuthSessionExpiryHandler? sessionExpiryHandler;
  final ShiftsRepository shiftsRepository;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final BalancesRepository balancesRepository;
  final StoreSettingsRepository storeSettingsRepository;
  final UserManagementRepository userManagementRepository;
  final ProductManagementRepository productManagementRepository;
  final CategoriesRepository categoriesRepository;
  final DiscountsRepository? discountsRepository;
  final PaymentMethodsRepository? paymentMethodsRepository;
  final VariantGroupsRepository variantGroupsRepository;
  final InventoryRepository? inventoryRepository;
  final ProductUnitsRepository? productUnitsRepository;
  final OutletsRepository? outletsRepository;
  final TableAreasRepository? tableAreasRepository;
  final TablesRepository? tablesRepository;
  final MembersRepository? membersRepository;
  final MembershipProgramsRepository? membershipProgramsRepository;

  Future<void> close() async {
    await database?.close();
  }
}
