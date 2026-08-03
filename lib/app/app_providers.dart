import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/finance/presentation/controllers/finance_controller.dart';
import '../features/inventory/presentation/controllers/inventory_controller.dart';
import '../features/pos/presentation/controllers/pos_controller.dart';
import '../features/purchasing/presentation/controllers/purchasing_controller.dart';
import '../features/restaurant_floor/presentation/controllers/restaurant_controller.dart';
import '../features/session/presentation/controllers/tenant_session_controller.dart';
import '../features/superadmin/presentation/controllers/superadmin_controller.dart';
import '../features/tenant_admin/presentation/controllers/tenant_admin_controller.dart';
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
    required this.restaurantController,
    required this.waiterController,
    required this.superadminController,
    required this.child,
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
  final Widget child;

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  String? _observedBranchId;

  @override
  void initState() {
    super.initState();
    _observedBranchId = widget.sessionController.activeBranchId;
    widget.sessionController.addListener(_syncSession);
  }

  void _syncSession() {
    final branchId = widget.sessionController.activeBranchId;
    widget.financeController.updateSession(
      isOwner: widget.sessionController.isOwner,
      branchId: branchId,
    );
    widget.restaurantController.updateSession(
      branchId: branchId,
      canUseFloor: widget.sessionController.hasAnyRole(const [
        'OWNER',
        'MANAGER',
        'WAITER',
        'CASHIER',
      ]),
      canUseKitchen: widget.sessionController.hasAnyRole(const [
        'OWNER',
        'MANAGER',
        'WAITER',
        'CHEF',
      ]),
    );
    widget.waiterController.updateBranch(branchId);
    if (branchId == _observedBranchId) return;
    _observedBranchId = branchId;
    widget.tenantAdminController.invalidate();
    widget.posController.setBranch(branchId);
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
    widget.restaurantController.load(force: true);
    if (widget.sessionController.hasAnyRole(const [
      'OWNER',
      'MANAGER',
      'WAITER',
      'CASHIER',
    ])) {
      widget.waiterController.loadMenu(force: true);
    }
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_syncSession);
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
      ChangeNotifierProvider.value(value: widget.restaurantController),
      ChangeNotifierProvider.value(value: widget.waiterController),
      ChangeNotifierProvider.value(value: widget.superadminController),
    ],
    child: widget.child,
  );
}
