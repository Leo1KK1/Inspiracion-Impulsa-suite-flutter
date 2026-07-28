import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/finance/presentation/controllers/finance_controller.dart';
import '../features/inventory/presentation/controllers/inventory_controller.dart';
import '../features/pos/presentation/controllers/pos_controller.dart';
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
    required this.inventoryController,
    required this.purchasingController,
    required this.posController,
    required this.financeController,
    required this.superadminController,
    required this.child,
  });

  final TenantSessionController sessionController;
  final TenantAdminController tenantAdminController;
  final InventoryController inventoryController;
  final PurchasingController purchasingController;
  final PosController posController;
  final FinanceController financeController;
  final SuperadminController superadminController;
  final Widget child;

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  late final RestaurantController restaurant;
  late final WaiterController waiter;
  String? _observedBranchId;

  @override
  void initState() {
    super.initState();
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
    widget.posController.setBranch(branchId);
    widget.financeController.onSessionBranchChanged(branchId);
    if (widget.sessionController.hasAnyRole(const ['OWNER', 'MANAGER'])) {
      widget.tenantAdminController.load(force: true);
      if (branchId != null) {
        widget.inventoryController
          ..setBranch(branchId)
          ..load(branchId: branchId, force: true);
        widget.purchasingController
          ..setBranch(branchId)
          ..load(branchId: branchId, force: true);
      }
    }
    if (branchId == null) return;
    if (widget.sessionController.hasAnyRole(const [
      'OWNER',
      'MANAGER',
      'CASHIER',
    ])) {
      widget.posController.load(branchId: branchId, force: true);
    }
    if (widget.sessionController.hasAnyRole(const ['OWNER', 'MANAGER'])) {
      widget.financeController.load(force: true);
    }
    restaurant.load(branchId: branchId);
    waiter.load(branchId: branchId);
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_syncBranch);
    restaurant.dispose();
    waiter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: widget.sessionController),
      ChangeNotifierProvider.value(value: widget.tenantAdminController),
      ChangeNotifierProvider.value(value: widget.inventoryController),
      ChangeNotifierProvider.value(value: widget.purchasingController),
      ChangeNotifierProvider.value(value: widget.posController),
      ChangeNotifierProvider.value(value: widget.financeController),
      ChangeNotifierProvider.value(value: restaurant),
      ChangeNotifierProvider.value(value: waiter),
      ChangeNotifierProvider.value(value: widget.superadminController),
    ],
    child: widget.child,
  );
}
