import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class WaiterShell extends StatelessWidget {
  const WaiterShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 820;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: AppColors.waiterNavy,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Servicio de mesas', style: TextStyle(fontSize: 16)),
            Text(
              'Sucursal CDMX Centro · WAITER',
              style: TextStyle(fontSize: 11, color: Color(0xFFB8D7E5)),
            ),
          ],
        ),
        actions: [
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
                switch (index) {
                  case 0:
                    context.go('/app/restaurant/waiter');
                  case 1:
                    context.go('/app/restaurant/waiter/orders/ORD-015');
                  case 2:
                    context.go('/app/pos/shifts/open');
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.table_restaurant_outlined),
                  label: 'Mesas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Comandas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.schedule_outlined),
                  label: 'Mi turno',
                ),
              ],
            )
          : null,
    );
  }

  int _selectedIndex(String location) {
    if (location.contains('/orders/')) return 1;
    if (location.contains('/shifts/')) return 2;
    return 0;
  }
}
