import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'features/session/data/repositories/session_repository.dart';
import 'features/session/presentation/controllers/tenant_session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  final session = TenantSessionController(PreferencesSessionRepository());
  await session.restore();
  runApp(ImpulsaSuiteApp(sessionController: session));
}
