import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'config/api_config.dart';
import 'features/balances/data/datasources/balances_remote_data_source.dart';
import 'features/balances/data/repositories/balances_repository_impl.dart';
import 'features/balances/domain/repositories/balances_repository.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/categories/data/datasources/categories_remote_data_source.dart';
import 'features/categories/data/repositories/categories_repository_impl.dart';
import 'features/categories/domain/repositories/categories_repository.dart';
import 'features/discounts/data/datasources/discounts_remote_data_source.dart';
import 'features/discounts/data/repositories/discounts_repository_impl.dart';
import 'features/discounts/domain/repositories/discounts_repository.dart';
import 'features/inventories/data/datasources/inventory_remote_data_source.dart';
import 'features/inventories/data/repositories/inventory_repository_impl.dart';
import 'features/inventories/domain/repositories/inventory_repository.dart';
import 'features/product_units/data/datasources/product_units_remote_data_source.dart';
import 'features/product_units/data/repositories/product_units_repository_impl.dart';
import 'features/product_units/domain/repositories/product_units_repository.dart';
import 'features/payment_method/data/datasources/payment_methods_remote_data_source.dart';
import 'features/payment_method/data/repositories/payment_methods_repository_impl.dart';
import 'features/payment_method/domain/repositories/payment_methods_repository.dart';
import 'features/outlets/data/datasources/outlets_remote_data_source.dart';
import 'features/outlets/data/repositories/outlets_repository_impl.dart';
import 'features/outlets/domain/repositories/outlets_repository.dart';
import 'features/table_areas/data/datasources/table_areas_remote_data_source.dart';
import 'features/table_areas/data/repositories/table_areas_repository_impl.dart';
import 'features/table_areas/domain/repositories/table_areas_repository.dart';
import 'features/tables/data/datasources/tables_remote_data_source.dart';
import 'features/tables/data/repositories/tables_repository_impl.dart';
import 'features/tables/domain/repositories/tables_repository.dart';
import 'features/products/data/datasources/product_management_remote_data_source.dart';
import 'features/products/data/repositories/product_management_repository_impl.dart';
import 'features/products/domain/repositories/product_management_repository.dart';
import 'features/products/data/datasources/catalog_remote_data_source.dart';
import 'features/products/data/repositories/catalog_repository_impl.dart';
import 'features/products/domain/repositories/catalog_repository.dart';
import 'features/shifts/data/datasources/shifts_remote_data_source.dart';
import 'features/shifts/data/repositories/shifts_repository_impl.dart';
import 'features/shifts/domain/repositories/shifts_repository.dart';
import 'features/store_settings/data/datasources/store_settings_remote_data_source.dart';
import 'features/store_settings/data/repositories/store_settings_repository_impl.dart';
import 'features/store_settings/domain/repositories/store_settings_repository.dart';
import 'features/transactions/data/datasources/checkout_remote_data_source.dart';
import 'features/transactions/data/repositories/checkout_repository_impl.dart';
import 'features/transactions/domain/repositories/checkout_repository.dart';
import 'features/members/data/datasources/members_remote_data_source.dart';
import 'features/members/data/repositories/members_repository_impl.dart';
import 'features/members/domain/repositories/members_repository.dart';
import 'features/users/data/datasources/users_remote_data_source.dart';
import 'features/users/data/repositories/user_management_repository_impl.dart';
import 'features/users/domain/repositories/user_management_repository.dart';
import 'features/variant_groups/data/datasources/variant_groups_remote_data_source.dart';
import 'features/variant_groups/data/repositories/variant_groups_repository_impl.dart';
import 'features/variant_groups/domain/repositories/variant_groups_repository.dart';
import 'features/splash/presentation/pages/kawula_splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final client = http.Client();
  final remoteDataSource = AuthRemoteDataSource(client, ApiConfig.baseUrl);
  final localDataSource = AuthLocalDataSource(const FlutterSecureStorage());
  final authRepository = AuthRepositoryImpl(remoteDataSource, localDataSource);
  final catalogRepository = CatalogRepositoryImpl(
    CatalogRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final shiftsRepository = ShiftsRepositoryImpl(
    ShiftsRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final membersRemoteDataSource = MembersRemoteDataSource(
    client,
    ApiConfig.baseUrl,
    localDataSource.readToken,
  );
  final membersRepository = MembersRepositoryImpl(membersRemoteDataSource);
  final checkoutRepository = CheckoutRepositoryImpl(
    CheckoutRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
      membersRemoteDataSource: membersRemoteDataSource,
    ),
  );
  final balancesRepository = BalancesRepositoryImpl(
    BalancesRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final storeSettingsRepository = StoreSettingsRepositoryImpl(
    StoreSettingsRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final userManagementRepository = UserManagementRepositoryImpl(
    UsersRemoteDataSource(client, ApiConfig.baseUrl, localDataSource.readToken),
  );
  final categoriesRepository = CategoriesRepositoryImpl(
    CategoriesRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final discountsRepository = DiscountsRepositoryImpl(
    DiscountsRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final paymentMethodsRepository = PaymentMethodsRepositoryImpl(
    PaymentMethodsRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final inventoryRepository = InventoryRepositoryImpl(
    InventoryRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final productUnitsRepository = ProductUnitsRepositoryImpl(
    ProductUnitsRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final variantGroupsRepository = VariantGroupsRepositoryImpl(
    VariantGroupsRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
    productUnitsRepository,
  );
  final productManagementRepository = ProductManagementRepositoryImpl(
    ProductManagementRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
    categoriesRepository,
    variantGroupsRepository,
    inventoryRepository,
    productUnitsRepository,
  );
  final outletsRepository = OutletsRepositoryImpl(
    OutletsRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final tableAreasRepository = TableAreasRepositoryImpl(
    TableAreasRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );
  final tablesRepository = TablesRepositoryImpl(
    TablesRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
  );

  runApp(
    KawulaPosApp(
      apiBaseUrl: ApiConfig.baseUrl,
      authRepository: authRepository,
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
    ),
  );
}

class KawulaPosApp extends StatelessWidget {
  const KawulaPosApp({
    super.key,
    required this.apiBaseUrl,
    required this.authRepository,
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
  });

  final AuthRepository authRepository;
  final String apiBaseUrl;
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authRepository)..restoreSession(),
      child: MaterialApp(
        title: 'Kawula',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: KawulaSplashScreen(
          child: AuthGate(
            apiBaseUrl: apiBaseUrl,
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
          ),
        ),
      ),
    );
  }
}
