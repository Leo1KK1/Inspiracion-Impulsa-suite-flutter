import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/session/presentation/controllers/tenant_session_controller.dart';
import 'app_providers.dart';
import 'app_router.dart';

class ImpulsaSuiteApp extends StatefulWidget {
  const ImpulsaSuiteApp({super.key, required this.sessionController});

  final TenantSessionController sessionController;

  @override
  State<ImpulsaSuiteApp> createState() => _ImpulsaSuiteAppState();
}

class _ImpulsaSuiteAppState extends State<ImpulsaSuiteApp> {
  late final router = createAppRouter(widget.sessionController);

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppProviders(
    sessionController: widget.sessionController,
    child: MaterialApp.router(
      title: 'Impulsa Suite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    ),
  );
}
