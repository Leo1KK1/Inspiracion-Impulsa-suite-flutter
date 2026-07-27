import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/finance/data/repositories/finance_repository.dart';
import '../features/finance/presentation/controllers/finance_controller.dart';
import '../features/inventory/data/repositories/inventory_repository.dart';
import '../features/inventory/presentation/controllers/inventory_controller.dart';
import '../features/pos/data/repositories/pos_repository.dart';
import '../features/pos/presentation/controllers/pos_controller.dart';
import '../features/purchasing/data/repositories/purchasing_repository.dart';
import '../features/purchasing/presentation/controllers/purchasing_controller.dart';
import '../features/restaurant_floor/data/repositories/restaurant_repository.dart';
import '../features/restaurant_floor/presentation/controllers/restaurant_controller.dart';
import '../features/session/presentation/controllers/tenant_session_controller.dart';
import '../features/superadmin/presentation/controllers/superadmin_controller.dart';
import '../features/tenant_admin/presentation/controllers/tenant_admin_controller.dart';
import '../features/waiter/data/repositories/waiter_repository.dart';
import '../features/waiter/presentation/controllers/waiter_controller.dart';

class AppProviders extends StatefulWidget {
  const AppProviders({
    super.key,
    required this.sessionController,
    required this.tenantAdminController,
    required this.superadminController,
    required this.child,
  });

  final TenantSessionController sessionController;
  final TenantAdminController tenantAdminController;
  final SuperadminController superadminController;
  final Widget child;

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late final InventoryController inventory;
  late final PurchasingController purchasing;
  late final PosController pos;
  late final FinanceController finance;
  late final RestaurantController restaurant;
  late final WaiterController waiter;
  String? _observedBranchId;

  @override
  void initState() {
    super.initState();
    inventory = InventoryController(MockInventoryRepository());
    purchasing = PurchasingController(MockPurchasingRepository());
    pos = PosController(MockPosRepository());
    finance = FinanceController(MockFinanceRepository());
    restaurant = RestaurantController(MockRestaurantRepository());
    waiter = WaiterController(MockWaiterRepository());
    _observedBranchId = widget.sessionController.activeBranchId;
    widget.sessionController.addListener(_syncBranch);
  }

  void _syncBranch() {
    final branchId = widget.sessionController.activeBranchId;
    if (branchId == _observedBranchId) return;
    _observedBranchId = branchId;
    widget.tenantAdminController.invalidate();
    if (widget.sessionController.hasAnyRole(const ['OWNER', 'MANAGER'])) {
      widget.tenantAdminController.load(force: true);
    }
    if (branchId == null) return;
    inventory.load(branchId: branchId);
    pos.load(branchId: branchId);
    restaurant.load(branchId: branchId);
    waiter.load(branchId: branchId);
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_syncBranch);
    inventory.dispose();
    purchasing.dispose();
    pos.dispose();
    finance.dispose();
    restaurant.dispose();
    waiter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.sessionController),
      ChangeNotifierProvider.value(value: widget.tenantAdminController),
      ChangeNotifierProvider.value(value: inventory),
      ChangeNotifierProvider.value(value: purchasing),
      ChangeNotifierProvider.value(value: pos),
      ChangeNotifierProvider.value(value: finance),
      ChangeNotifierProvider.value(value: restaurant),
      ChangeNotifierProvider.value(value: waiter),
      ChangeNotifierProvider.value(value: widget.superadminController),
    ],
    child: widget.child,
  );
}
