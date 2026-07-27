import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'features/session/data/repositories/session_repository.dart';
import 'features/session/presentation/controllers/tenant_session_controller.dart';
import 'features/superadmin/data/repositories/superadmin_repository.dart';
import 'features/superadmin/data/repositories/superadmin_session_store.dart';
import 'features/superadmin/presentation/controllers/superadmin_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  final session = TenantSessionController(PreferencesSessionRepository());
  await session.restore();
  final superadmin = SuperadminController(
    HttpSuperadminRepository(
      DioClient(baseUrl: AppConfig.apiBaseUrl),
      PreferencesSuperadminSessionStore(),
    ),
  );
  await superadmin.restore();
  runApp(
    ImpulsaSuiteApp(
      sessionController: session,
      superadminController: superadmin,
    ),
  );
}
