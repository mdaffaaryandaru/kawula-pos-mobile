import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'config/api_config.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/products/data/datasources/catalog_remote_data_source.dart';
import 'features/products/data/repositories/catalog_repository_impl.dart';
import 'features/products/domain/repositories/catalog_repository.dart';
import 'features/shifts/data/datasources/shifts_remote_data_source.dart';
import 'features/shifts/data/repositories/shifts_repository_impl.dart';
import 'features/shifts/domain/repositories/shifts_repository.dart';
import 'features/transactions/data/datasources/checkout_remote_data_source.dart';
import 'features/transactions/data/repositories/checkout_repository_impl.dart';
import 'features/transactions/domain/repositories/checkout_repository.dart';
import 'features/users/data/datasources/users_remote_data_source.dart';
import 'features/users/data/repositories/user_management_repository_impl.dart';
import 'features/users/domain/repositories/user_management_repository.dart';

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
    ),
  );
  final userManagementRepository = UserManagementRepositoryImpl(
    UsersRemoteDataSource(client, ApiConfig.baseUrl, localDataSource.readToken),
  );

  runApp(
    KawulaPosApp(
      authRepository: authRepository,
      shiftsRepository: shiftsRepository,
      catalogRepository: catalogRepository,
      checkoutRepository: checkoutRepository,
      userManagementRepository: userManagementRepository,
    ),
  );
}

class KawulaPosApp extends StatelessWidget {
  const KawulaPosApp({
    super.key,
    required this.authRepository,
    required this.shiftsRepository,
    required this.catalogRepository,
    required this.checkoutRepository,
    required this.userManagementRepository,
  });

  final AuthRepository authRepository;
  final ShiftsRepository shiftsRepository;
  final CatalogRepository catalogRepository;
  final CheckoutRepository checkoutRepository;
  final UserManagementRepository userManagementRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authRepository)..restoreSession(),
      child: MaterialApp(
        title: 'Kawula POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 23, 34, 107),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: AuthGate(
          shiftsRepository: shiftsRepository,
          catalogRepository: catalogRepository,
          checkoutRepository: checkoutRepository,
          userManagementRepository: userManagementRepository,
        ),
      ),
    );
  }
}
