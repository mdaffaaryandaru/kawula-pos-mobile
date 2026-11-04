// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Project imports:
import 'package:kawula_pos/app/kawula_pos_app.dart';
import 'package:kawula_pos/bootstrap/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final dependencies = AppDependencies.create();
  runApp(KawulaPosApp(dependencies: dependencies));
}
