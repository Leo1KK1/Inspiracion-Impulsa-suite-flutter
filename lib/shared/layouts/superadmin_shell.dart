import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class SuperadminShell extends StatelessWidget {
  const SuperadminShell({super.key, required this.child});
  final Widget child;

  static const items = [
    ('/superadmin/dashboard', 'Dashboard', Icons.dashboard_outlined),
    ('/superadmin/tenants', 'Tenants', Icons.business_outlined),
    ('/superadmin/users', 'Usuarios', Icons.people_outline),
    ('/superadmin/billing', 'Facturación', Icons.credit_card_outlined),
    ('/superadmin/analytics', 'Analytics', Icons.query_stats_outlined),
    ('/superadmin/settings', 'Configuración', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.desktop;
    final navigation = _SuperadminNavigation(items: items);
    if (compact) {
      return Scaffold(
        appBar: AppBar(title: const Text('Impulsa Suite · Superadmin')),
        drawer: Drawer(child: navigation),
        body: child,
      );
    }
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 240, child: navigation),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 68,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 280,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar tenants, usuarios…',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const CircleAvatar(child: Text('AP')),
                      const SizedBox(width: 10),
                      const Text('Ana Pérez · Superadmin'),
                      const SizedBox(width: 14),
                      IconButton(
                        tooltip: 'Cerrar sesión',
                        onPressed: () => context.go('/superadmin/login'),
                        icon: const Icon(Icons.logout),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuperadminNavigation extends StatelessWidget {
  const _SuperadminNavigation({required this.items});
  final List<(String, String, IconData)> items;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return ColoredBox(
      color: AppColors.superadminSidebar,
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.bolt, color: Colors.white),
              title: Text(
                'Impulsa Suite',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                'Superadmin',
                style: TextStyle(color: Color(0xFF9AA9DB)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        selected: location.startsWith(item.$1),
                        selectedTileColor: Colors.white.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        leading: Icon(item.$3, color: const Color(0xFFC7D2FE)),
                        title: Text(
                          item.$2,
                          style: const TextStyle(color: Color(0xFFC7D2FE)),
                        ),
                        onTap: () => context.go(item.$1),
                      ),
                    ),
                ],
              ),
            ),
            const ListTile(
              leading: CircleAvatar(radius: 14, child: Text('AP')),
              title: Text(
                'Ana Pérez',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              subtitle: Text(
                'ana@impulsa.io',
                style: TextStyle(color: Color(0xFF9AA9DB), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
