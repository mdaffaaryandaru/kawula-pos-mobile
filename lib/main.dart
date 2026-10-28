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
import 'features/inventories/data/datasources/inventory_remote_data_source.dart';
import 'features/inventories/data/repositories/inventory_repository_impl.dart';
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
import 'features/users/data/datasources/users_remote_data_source.dart';
import 'features/users/data/repositories/user_management_repository_impl.dart';
import 'features/users/domain/repositories/user_management_repository.dart';
import 'features/variant_groups/data/datasources/variant_groups_remote_data_source.dart';
import 'features/variant_groups/data/repositories/variant_groups_repository_impl.dart';
import 'features/variant_groups/domain/repositories/variant_groups_repository.dart';
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
  final checkoutRepository = CheckoutRepositoryImpl(
    CheckoutRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
      membersRemoteDataSource: MembersRemoteDataSource(
        client,
        ApiConfig.baseUrl,
        localDataSource.readToken,
      ),
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
  final variantGroupsRepository = VariantGroupsRepositoryImpl(
    VariantGroupsRemoteDataSource(
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
  final productManagementRepository = ProductManagementRepositoryImpl(
    ProductManagementRemoteDataSource(
      client,
      ApiConfig.baseUrl,
      localDataSource.readToken,
    ),
    categoriesRepository,
    variantGroupsRepository,
    inventoryRepository,
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
      variantGroupsRepository: variantGroupsRepository,
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
  final VariantGroupsRepository variantGroupsRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authRepository)..restoreSession(),
      child: MaterialApp(
        title: 'Kawula POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: AuthGate(
          apiBaseUrl: apiBaseUrl,
          shiftsRepository: shiftsRepository,
          catalogRepository: catalogRepository,
          checkoutRepository: checkoutRepository,
          balancesRepository: balancesRepository,
          storeSettingsRepository: storeSettingsRepository,
          userManagementRepository: userManagementRepository,
          productManagementRepository: productManagementRepository,
          categoriesRepository: categoriesRepository,
          variantGroupsRepository: variantGroupsRepository,
        ),
      ),
    );
  }
}
