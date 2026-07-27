import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/presentation/pages/analytics_dashboard_page.dart';
import '../features/analytics/presentation/pages/financial_health_page.dart';
import '../features/auth/presentation/pages/home_selector_page.dart';
import '../features/auth/presentation/pages/superadmin_login_page.dart';
import '../features/auth/presentation/pages/tenant_login_page.dart';
import '../features/finance/presentation/pages/expense_categories_page.dart';
import '../features/finance/presentation/pages/expense_detail_page.dart';
import '../features/finance/presentation/pages/expenses_page.dart';
import '../features/inventory/presentation/pages/inventory_alerts_page.dart';
import '../features/inventory/presentation/pages/inventory_categories_page.dart';
import '../features/inventory/presentation/pages/inventory_dashboard_page.dart';
import '../features/inventory/presentation/pages/product_detail_page.dart';
import '../features/inventory/presentation/pages/products_page.dart';
import '../features/pos/presentation/pages/checkout_page.dart';
import '../features/pos/presentation/pages/pos_page.dart';
import '../features/pos/presentation/pages/shift_pages.dart';
import '../features/pos/presentation/pages/tickets_page.dart';
import '../features/purchasing/presentation/pages/purchase_order_detail_page.dart';
import '../features/purchasing/presentation/pages/purchase_orders_page.dart';
import '../features/purchasing/presentation/pages/suppliers_page.dart';
import '../features/restaurant_floor/presentation/pages/kitchen_board_page.dart';
import '../features/restaurant_floor/presentation/pages/restaurant_floor_page.dart';
import '../features/restaurant_floor/presentation/pages/table_detail_page.dart';
import '../features/session/presentation/controllers/tenant_session_controller.dart';
import '../features/superadmin/presentation/pages/superadmin_pages.dart';
import '../features/superadmin/presentation/controllers/superadmin_controller.dart';
import '../features/tenant_admin/presentation/pages/branch_context_page.dart';
import '../features/tenant_admin/presentation/pages/branches_page.dart';
import '../features/tenant_admin/presentation/pages/multibranch_controller_page.dart';
import '../features/tenant_admin/presentation/pages/profile_page.dart';
import '../features/tenant_admin/presentation/pages/roles_page.dart';
import '../features/tenant_admin/presentation/pages/tenant_dashboard_page.dart';
import '../features/tenant_admin/presentation/pages/users_page.dart';
import '../features/waiter/presentation/pages/order_status_page.dart';
import '../features/waiter/presentation/pages/split_bill_page.dart';
import '../features/waiter/presentation/pages/table_session_page.dart';
import '../features/waiter/presentation/pages/waiter_table_selector_page.dart';
import '../shared/layouts/pos_shell.dart';
import '../shared/layouts/superadmin_shell.dart';
import '../shared/layouts/tenant_admin_shell.dart';
import '../shared/layouts/waiter_shell.dart';
import '../shared/pages/reference_state_page.dart';
import '../shared/widgets/app_states.dart';
import 'route_guards.dart';

GoRouter createAppRouter(
  TenantSessionController session,
  SuperadminController superadmin,
) => GoRouter(
  initialLocation: '/',
  refreshListenable: Listenable.merge([session, superadmin]),
  redirect: (context, state) => _redirect(session, superadmin, state.uri.path),
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeSelectorPage()),
    GoRoute(path: '/tenant-login', builder: (_, _) => const TenantLoginPage()),
    GoRoute(path: '/tenant/login', builder: (_, _) => const TenantLoginPage()),
    GoRoute(
      path: '/superadmin/login',
      builder: (_, _) => const SuperadminLoginPage(),
    ),
    GoRoute(
      path: '/design-system',
      builder: (_, _) => const DesignSystemPage(),
    ),
    _superadminRoutes(),
    _tenantAdminRoutes(),
    _posRoutes(),
    _waiterRoutes(),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: AppErrorState(
      message: 'La ruta ${state.uri.path} no existe.',
      onRetry: () => context.go('/'),
    ),
  ),
);

String? _redirect(
  TenantSessionController session,
  SuperadminController superadmin,
  String location,
) {
  if (location == '/tenant/login') return '/tenant-login';
  if (location == '/app/admin/multibranch-controller') {
    return '/app/admin/multibranch';
  }
  if (location == '/superadmin') return '/superadmin/dashboard';
  if (location == '/app') return '/app/dashboard';
  if (location == '/superadmin/login' && superadmin.isAuthenticated) {
    return '/superadmin/dashboard';
  }
  if (location.startsWith('/superadmin/') &&
      location != '/superadmin/login' &&
      !superadmin.isAuthenticated) {
    return '/superadmin/login?from=${Uri.encodeComponent(location)}';
  }
  if (location == '/tenant-login' && session.isAuthenticated) {
    return '/app/dashboard';
  }
  if (!location.startsWith('/app')) return null;

  final tenantRedirect = TenantGuard.redirect(session, location);
  if (tenantRedirect != null &&
      location != '/app/access-denied' &&
      location != '/app/tenant-suspended') {
    return tenantRedirect;
  }
  if (location == '/app/access-denied' ||
      location == '/app/tenant-suspended') {
    return null;
  }

  final requiresBranch =
      location.startsWith('/app/pos') ||
      location.startsWith('/app/admin/inventory') ||
      location.startsWith('/app/admin/purchasing') ||
      location.startsWith('/app/admin/analytics') ||
      location.startsWith('/app/admin/finance') ||
      location.startsWith('/app/restaurant');
  if (requiresBranch) {
    final branchRedirect = BranchContextGuard.redirect(session);
    if (branchRedirect != null) return branchRedirect;
  }
  if (location.startsWith('/app/restaurant/waiter')) {
    return WaiterRoleGuard.redirect(session);
  }
  if (location.startsWith('/app/pos')) {
    return PosRoleGuard.redirect(session);
  }
  if (location.startsWith('/app/admin') ||
      location.startsWith('/app/restaurant/floor') ||
      location.startsWith('/app/restaurant/kitchen-board')) {
    return AdminRoleGuard.redirect(session);
  }
  return null;
}

ShellRoute _superadminRoutes() => ShellRoute(
  builder: (_, _, child) => SuperadminShell(child: child),
  routes: [
    GoRoute(
      path: '/superadmin/dashboard',
      builder: (_, _) => const SuperadminDashboardPage(),
    ),
    GoRoute(
      path: '/superadmin/tenants',
      builder: (_, _) => const SuperadminTenantsPage(),
    ),
    GoRoute(
      path: '/superadmin/tenants/:tenantId',
      builder: (_, state) => SuperadminTenantDetailPage(
        tenantId: state.pathParameters['tenantId']!,
      ),
    ),
    _superadminModule(
      '/superadmin/users',
      'Usuarios · Superadmin',
      'Administración global de acceso.',
      Icons.people_outline,
    ),
    _superadminModule(
      '/superadmin/billing',
      'Facturación · Superadmin',
      'Planes, renovaciones y cobranza de plataforma.',
      Icons.credit_card_outlined,
    ),
    _superadminModule(
      '/superadmin/analytics',
      'Analytics · Superadmin',
      'Indicadores consolidados de adopción.',
      Icons.query_stats_outlined,
    ),
    _superadminModule(
      '/superadmin/settings',
      'Configuración · Superadmin',
      'Parámetros globales de plataforma.',
      Icons.settings_outlined,
    ),
  ],
);

GoRoute _superadminModule(
  String path,
  String title,
  String description,
  IconData icon,
) => GoRoute(
  path: path,
  builder: (_, _) =>
      SuperadminModulePage(title: title, description: description, icon: icon),
);

ShellRoute _tenantAdminRoutes() => ShellRoute(
  builder: (_, _, child) => TenantAdminShell(child: child),
  routes: [
    GoRoute(
      path: '/app/dashboard',
      builder: (_, _) => const TenantDashboardPage(),
    ),
    GoRoute(path: '/app/profile', builder: (_, _) => const ProfilePage()),
    GoRoute(
      path: '/app/branch-context',
      builder: (_, _) => const BranchContextPage(),
    ),
    GoRoute(
      path: '/app/access-denied',
      builder: (_, _) => const AccessDeniedPage(),
    ),
    GoRoute(
      path: '/app/tenant-suspended',
      builder: (_, _) => const TenantSuspendedState(),
    ),
    GoRoute(
      path: '/app/empty-state',
      builder: (_, _) => const OperationalEmptyState(
        title: 'Sin información disponible',
        message: 'No hay datos para el contexto seleccionado.',
      ),
    ),
    GoRoute(
      path: '/app/admin/dashboard',
      builder: (_, _) => const TenantDashboardPage(),
    ),
    GoRoute(
      path: '/app/admin/branches',
      builder: (_, _) => const BranchesPage(),
    ),
    GoRoute(
      path: '/app/admin/users',
      builder: (_, _) => const TenantUsersPage(),
    ),
    GoRoute(
      path: '/app/admin/roles',
      builder: (_, _) => const TenantRolesPage(),
    ),
    GoRoute(
      path: '/app/admin/multibranch',
      builder: (_, _) => const MultibranchControllerPage(),
    ),
    GoRoute(
      path: '/app/admin/inventory/dashboard',
      builder: (_, _) => const InventoryDashboardPage(),
    ),
    GoRoute(
      path: '/app/admin/inventory/products',
      builder: (_, _) => const ProductsPage(),
    ),
    GoRoute(
      path: '/app/admin/inventory/products/:productId',
      builder: (_, state) =>
          ProductDetailPage(productId: state.pathParameters['productId']!),
    ),
    GoRoute(
      path: '/app/admin/inventory/categories',
      builder: (_, _) => const InventoryCategoriesPage(),
    ),
    GoRoute(
      path: '/app/admin/inventory/alerts',
      builder: (_, _) => const InventoryAlertsPage(),
    ),
    GoRoute(
      path: '/app/admin/purchasing/orders',
      builder: (_, _) => const PurchaseOrdersPage(),
    ),
    GoRoute(
      path: '/app/admin/purchasing/orders/:purchaseOrderId',
      builder: (_, state) => PurchaseOrderDetailPage(
        orderId: state.pathParameters['purchaseOrderId']!,
      ),
    ),
    GoRoute(
      path: '/app/admin/purchasing/suppliers',
      builder: (_, _) => const SuppliersPage(),
    ),
    GoRoute(
      path: '/app/admin/analytics/dashboard',
      builder: (_, _) => const AnalyticsDashboardPage(),
    ),
    GoRoute(
      path: '/app/admin/analytics/financial-health',
      builder: (_, _) => const FinancialHealthPage(),
    ),
    GoRoute(
      path: '/app/admin/finance/expenses',
      builder: (_, _) => const ExpensesPage(),
    ),
    GoRoute(
      path: '/app/admin/finance/expenses/:id',
      builder: (_, state) =>
          ExpenseDetailPage(expenseId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/app/admin/finance/categories',
      builder: (_, _) => const ExpenseCategoriesPage(),
    ),
    GoRoute(
      path: '/app/restaurant/floor',
      builder: (_, _) => const RestaurantFloorPage(),
    ),
    GoRoute(
      path: '/app/restaurant/floor/:tableId',
      builder: (_, state) =>
          TableDetailPage(tableId: state.pathParameters['tableId']!),
    ),
    GoRoute(
      path: '/app/restaurant/kitchen-board',
      builder: (_, _) => const KitchenBoardPage(),
    ),
    _referenceRoute('/app/orders', 'Pedidos'),
    _referenceRoute('/app/reports', 'Reportes'),
    _referenceRoute('/app/settings', 'Configuración · Tenant'),
  ],
);

GoRoute _referenceRoute(String path, String title) => GoRoute(
  path: path,
  builder: (_, _) => ReferenceStatePage(
    title: title,
    description: 'Ruta preservada desde React.',
  ),
);

ShellRoute _posRoutes() => ShellRoute(
  builder: (_, _, child) => PosShell(child: child),
  routes: [
    GoRoute(path: '/app/pos', builder: (_, _) => const PosPage()),
    GoRoute(path: '/app/pos/checkout', builder: (_, _) => const CheckoutPage()),
    GoRoute(
      path: '/app/pos/shifts/open',
      builder: (_, _) => const OpenShiftPage(),
    ),
    GoRoute(
      path: '/app/pos/shifts/close',
      builder: (_, _) => const CloseShiftPage(),
    ),
    GoRoute(path: '/app/pos/tickets', builder: (_, _) => const TicketsPage()),
    GoRoute(
      path: '/app/pos/tickets/:ticketId',
      builder: (_, state) =>
          TicketsPage(ticketId: state.pathParameters['ticketId']),
    ),
  ],
);

ShellRoute _waiterRoutes() => ShellRoute(
  builder: (_, _, child) => WaiterShell(child: child),
  routes: [
    GoRoute(
      path: '/app/restaurant/waiter',
      builder: (_, _) => const WaiterTableSelectorPage(),
    ),
    GoRoute(
      path: '/app/restaurant/waiter/tables/:tableId',
      builder: (_, state) =>
          TableSessionPage(tableId: state.pathParameters['tableId']!),
    ),
    GoRoute(
      path: '/app/restaurant/waiter/orders/:orderId',
      builder: (_, state) =>
          OrderStatusPage(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/app/restaurant/waiter/split-bill/:tableId',
      builder: (_, state) =>
          SplitBillPage(tableId: state.pathParameters['tableId']!),
    ),
  ],
);
