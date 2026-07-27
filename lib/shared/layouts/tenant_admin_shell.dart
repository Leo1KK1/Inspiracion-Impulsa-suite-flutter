import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/session/presentation/controllers/tenant_session_controller.dart';
import '../widgets/app_badges.dart';

class TenantAdminShell extends StatelessWidget {
  const TenantAdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.desktop;
    if (compact) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Impulsa Suite'),
          actions: [
            IconButton(
              tooltip: 'Cambiar sucursal',
              onPressed: () => context.go('/app/branch-context'),
              icon: const Icon(Icons.account_tree_outlined),
            ),
          ],
        ),
        drawer: const Drawer(child: _TenantNavigation()),
        body: child,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(width: 248, child: _TenantNavigation()),
          Expanded(
            child: Column(
              children: [
                const _TenantTopbar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantTopbar extends StatelessWidget {
  const _TenantTopbar();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TenantSessionController>();
    final session = controller.session;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 290,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar módulos y acciones…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          const Spacer(),
          BranchContextBadge(
            branch: session?.activeBranchName ?? 'Sin sucursal',
          ),
          const SizedBox(width: 8),
          RoleBadge(role: controller.roleCodes.firstOrNull ?? 'VIEWER'),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Badge(
              smallSize: 7,
              child: Icon(Icons.notifications_none),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            onSelected: (value) async {
              if (value == 'profile') context.go('/app/profile');
              if (value == 'logout') {
                await controller.logout();
                if (context.mounted) context.go('/tenant-login');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Mi perfil')),
              PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
            ],
            child: CircleAvatar(
              backgroundColor: AppColors.tenantAccent,
              child: Text(
                _initials(session?.userName ?? 'Usuario'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TenantNavigation extends StatelessWidget {
  const _TenantNavigation();

  static const groups = <_NavGroup>[
    _NavGroup('Operaciones', [
      _NavItem('/app/dashboard', 'Inicio', Icons.dashboard_outlined),
      _NavItem('/app/pos', 'Punto de venta', Icons.shopping_cart_outlined),
    ]),
    _NavGroup('Administración', [
      _NavItem(
        '/app/admin/branches',
        'Sucursales',
        Icons.store_mall_directory_outlined,
      ),
      _NavItem('/app/admin/users', 'Empleados', Icons.people_outline),
      _NavItem('/app/admin/roles', 'Roles', Icons.shield_outlined),
      _NavItem(
        '/app/admin/multibranch-controller',
        'Multisucursal',
        Icons.hub_outlined,
      ),
    ]),
    _NavGroup('Inventario', [
      _NavItem(
        '/app/admin/inventory/dashboard',
        'Dashboard',
        Icons.grid_view_outlined,
      ),
      _NavItem(
        '/app/admin/inventory/products',
        'Productos',
        Icons.inventory_2_outlined,
      ),
      _NavItem(
        '/app/admin/inventory/categories',
        'Categorías',
        Icons.sell_outlined,
      ),
      _NavItem(
        '/app/admin/inventory/alerts',
        'Alertas',
        Icons.warning_amber_outlined,
      ),
    ]),
    _NavGroup('Compras', [
      _NavItem(
        '/app/admin/purchasing/orders',
        'Órdenes',
        Icons.local_shipping_outlined,
      ),
      _NavItem(
        '/app/admin/purchasing/suppliers',
        'Proveedores',
        Icons.handshake_outlined,
      ),
    ]),
    _NavGroup('Restaurante', [
      _NavItem(
        '/app/restaurant/floor',
        'Plano de mesas',
        Icons.table_restaurant_outlined,
      ),
      _NavItem(
        '/app/restaurant/kitchen-board',
        'Tablero cocina',
        Icons.soup_kitchen_outlined,
      ),
      _NavItem('/app/restaurant/waiter', 'Módulo mesero', Icons.room_service),
    ]),
    _NavGroup('Analítica', [
      _NavItem(
        '/app/admin/analytics/dashboard',
        'Dashboard financiero',
        Icons.query_stats_outlined,
      ),
      _NavItem(
        '/app/admin/analytics/financial-health',
        'Salud financiera',
        Icons.monitor_heart_outlined,
      ),
    ]),
    _NavGroup('Finanzas', [
      _NavItem(
        '/app/admin/finance/expenses',
        'Gastos',
        Icons.payments_outlined,
      ),
      _NavItem(
        '/app/admin/finance/categories',
        'Categorías de gasto',
        Icons.category_outlined,
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TenantSessionController>().session;
    return ColoredBox(
      color: AppColors.tenantSidebar,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x260D9488),
                child: Icon(Icons.storefront, color: AppColors.tenantAccent),
              ),
              title: Text(
                session?.tenantName ?? 'Impulsa Suite',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Enterprise plan',
                style: TextStyle(color: Color(0xFF5F8E8A), fontSize: 11),
              ),
            ),
            InkWell(
              onTap: () => context.go('/app/branch-context'),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_tree_outlined,
                      color: AppColors.tenantAccent,
                      size: 17,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        session?.activeBranchName ?? 'Elegir sucursal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF5F8E8A),
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 3, 10, 20),
                children: [
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 13, 12, 5),
                      child: Text(
                        group.label.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF49716E),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    for (final item in group.items) _NavigationTile(item: item),
                  ],
                ],
              ),
            ),
            const Divider(color: Color(0x1AFFFFFF), height: 1),
            ListTile(
              onTap: () => context.go('/app/profile'),
              leading: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.tenantAccent,
                child: Text(
                  _initials(session?.userName ?? 'Usuario'),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              title: Text(
                session?.userName ?? 'Usuario',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              subtitle: Text(
                session?.roleCodes.firstOrNull ?? 'VIEWER',
                style: const TextStyle(color: Color(0xFF5F8E8A), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.item});
  final _NavItem item;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected =
        location == item.path || location.startsWith('${item.path}/');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: AppColors.tenantAccent.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        leading: Icon(
          item.icon,
          size: 18,
          color: selected ? Colors.white : const Color(0xFF6C9C98),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF94B8B5),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {
          context.go(item.path);
          if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }
}

class _NavGroup {
  const _NavGroup(this.label, this.items);
  final String label;
  final List<_NavItem> items;
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

String _initials(String name) {
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();
}
