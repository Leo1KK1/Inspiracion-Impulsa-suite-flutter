import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/superadmin/presentation/controllers/superadmin_controller.dart';

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
    final controller = context.watch<SuperadminController>();
    final user = controller.currentUser;
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.desktop;
    final navigation = _SuperadminNavigation(
      items: items,
      fullName: user?.fullName ?? 'Superadmin',
      email: user?.email ?? '',
    );
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
                      const Row(
                        children: [
                          Icon(Icons.public_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Contexto global · Superadmin',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Spacer(),
                      CircleAvatar(child: Text(_initials(user?.fullName))),
                      const SizedBox(width: 10),
                      Text('${user?.fullName ?? 'Superadmin'} · Superadmin'),
                      const SizedBox(width: 14),
                      IconButton(
                        tooltip: 'Cerrar sesión',
                        onPressed: controller.saving
                            ? null
                            : () async {
                                await controller.logout();
                                if (context.mounted) {
                                  context.go('/superadmin/login');
                                }
                              },
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

  static String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    return parts.isEmpty
        ? 'SA'
        : parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _SuperadminNavigation extends StatelessWidget {
  const _SuperadminNavigation({
    required this.items,
    required this.fullName,
    required this.email,
  });
  final List<(String, String, IconData)> items;
  final String fullName;
  final String email;

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
            ListTile(
              leading: CircleAvatar(
                radius: 14,
                child: Text(SuperadminShell._initials(fullName)),
              ),
              title: Text(
                fullName,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              subtitle: Text(
                email,
                style: TextStyle(color: Color(0xFF9AA9DB), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
