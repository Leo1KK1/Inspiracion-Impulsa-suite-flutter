import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../features/session/presentation/controllers/tenant_session_controller.dart';

class WaiterShell extends StatelessWidget {
  const WaiterShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 820;
    final session = context.watch<TenantSessionController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: AppColors.waiterNavy,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Servicio de mesas', style: TextStyle(fontSize: 16)),
            Text(
              '${session.session?.activeBranchName ?? 'Sin sucursal'} · '
              '${session.roleCodes.firstOrNull ?? 'USUARIO'}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFB8D7E5)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cambiar sucursal',
            onPressed: session.canSwitchBranch
                ? () => context.go('/app/branch-context')
                : null,
            icon: const Icon(Icons.account_tree_outlined),
          ),
          if (session.hasAnyRole(const ['OWNER', 'MANAGER']))
            IconButton(
              tooltip: 'Panel administrativo',
              onPressed: () => context.go('/app/dashboard'),
              icon: const Icon(Icons.dashboard_outlined),
            ),
        ],
      ),
      body: child,
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: _selectedIndex(GoRouterState.of(context).uri.path),
              onDestinationSelected: (index) {
                if (index == 0) {
                  context.go('/app/restaurant/waiter');
                } else {
                  context.go('/app/restaurant/kitchen-board');
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.table_restaurant_outlined),
                  label: 'Mesas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.soup_kitchen_outlined),
                  label: 'Cocina',
                ),
              ],
            )
          : null,
    );
  }

  int _selectedIndex(String location) =>
      location.contains('/kitchen-board') ? 1 : 0;
}
