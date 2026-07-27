import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'features/inventory/data/repositories/inventory_repository.dart';
import 'features/inventory/presentation/controllers/inventory_controller.dart';
import 'features/pos/data/repositories/pos_repository.dart';
import 'features/pos/presentation/controllers/pos_controller.dart';
import 'features/purchasing/data/repositories/purchasing_repository.dart';
import 'features/purchasing/presentation/controllers/purchasing_controller.dart';
import 'features/session/data/repositories/session_repository.dart';
import 'features/session/presentation/controllers/tenant_session_controller.dart';
import 'features/superadmin/data/repositories/superadmin_repository.dart';
import 'features/superadmin/data/repositories/superadmin_session_store.dart';
import 'features/superadmin/presentation/controllers/superadmin_controller.dart';
import 'features/tenant_admin/data/repositories/tenant_admin_repository.dart';
import 'features/tenant_admin/presentation/controllers/tenant_admin_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  final tenantClient = DioClient(baseUrl: AppConfig.apiBaseUrl);
  final session = TenantSessionController(
    HttpTenantSessionRepository(tenantClient, PreferencesTenantSessionStore()),
  );
  await session.restore();
  final tenantAdmin = TenantAdminController(
    HttpTenantAdminRepository(tenantClient),
  );
  final inventory = InventoryController(
    HttpInventoryRepository(tenantClient),
    initialBranchId: session.activeBranchId,
  );
  final purchasing = PurchasingController(
    HttpPurchasingRepository(tenantClient),
    initialBranchId: session.activeBranchId,
  );
  final pos = PosController(
    HttpPosRepository(tenantClient),
    initialBranchId: session.activeBranchId,
    canManageShifts: session.hasAnyRole(const ['OWNER', 'MANAGER']),
  );
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
      tenantAdminController: tenantAdmin,
      inventoryController: inventory,
      purchasingController: purchasing,
      posController: pos,
      superadminController: superadmin,
    ),
  );
}
