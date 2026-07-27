import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class PosShell extends StatelessWidget {
  const PosShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8FA),
    appBar: AppBar(
      backgroundColor: AppColors.tenantSidebar,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'Volver al panel',
        onPressed: () => context.go('/app/dashboard'),
        icon: const Icon(Icons.arrow_back),
      ),
      title: const Row(
        children: [
          Icon(Icons.point_of_sale),
          SizedBox(width: 10),
          Text('Punto de venta · CDMX Centro'),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/app/pos/tickets'),
          icon: const Icon(Icons.receipt_long, color: Colors.white),
          label: const Text('Tickets', style: TextStyle(color: Colors.white)),
        ),
        TextButton.icon(
          onPressed: () => context.go('/app/pos/shifts/close'),
          icon: const Icon(Icons.lock_clock, color: Colors.white),
          label: const Text(
            'Cerrar turno',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: child,
  );
}
