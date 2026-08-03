import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/finance/presentation/controllers/finance_controller.dart';
import '../features/inventory/presentation/controllers/inventory_controller.dart';
import '../features/pos/presentation/controllers/pos_controller.dart';
import '../features/purchasing/presentation/controllers/purchasing_controller.dart';
import '../features/restaurant_floor/presentation/controllers/restaurant_controller.dart';
import '../features/session/presentation/controllers/tenant_session_controller.dart';
import '../features/superadmin/presentation/controllers/superadmin_controller.dart';
import '../features/tenant_admin/presentation/controllers/tenant_admin_controller.dart';
import '../features/waiter/presentation/controllers/waiter_controller.dart';
import 'app_providers.dart';
import 'app_router.dart';

class ImpulsaSuiteApp extends StatefulWidget {
  const ImpulsaSuiteApp({
    super.key,
    required this.sessionController,
    required this.tenantAdminController,
    required this.inventoryController,
    required this.purchasingController,
    required this.posController,
    required this.financeController,
    required this.restaurantController,
    required this.waiterController,
    required this.superadminController,
  });

  final TenantSessionController sessionController;
  final TenantAdminController tenantAdminController;
  final InventoryController inventoryController;
  final PurchasingController purchasingController;
  final PosController posController;
  final FinanceController financeController;
  final RestaurantController restaurantController;
  final WaiterController waiterController;
  final SuperadminController superadminController;

  @override
  State<ImpulsaSuiteApp> createState() => _ImpulsaSuiteAppState();
}

class _ImpulsaSuiteAppState extends State<ImpulsaSuiteApp> {
  late final router = createAppRouter(
    widget.sessionController,
    widget.superadminController,
  );

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppProviders(
    sessionController: widget.sessionController,
    tenantAdminController: widget.tenantAdminController,
    inventoryController: widget.inventoryController,
    purchasingController: widget.purchasingController,
    posController: widget.posController,
    financeController: widget.financeController,
    restaurantController: widget.restaurantController,
    waiterController: widget.waiterController,
    superadminController: widget.superadminController,
    child: MaterialApp.router(
      title: 'Impulsa Suite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    ),
  );
}
