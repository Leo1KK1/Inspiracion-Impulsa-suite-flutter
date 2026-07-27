import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../features/pos/presentation/controllers/pos_controller.dart';
import '../../features/session/presentation/controllers/tenant_session_controller.dart';

class PosShell extends StatelessWidget {
  const PosShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TenantSessionController>();
    final pos = context.watch<PosController>();
    final branchName = session.session?.activeBranchName ?? 'Sucursal activa';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: AppColors.tenantSidebar,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Volver al panel',
          onPressed: () => context.go('/app/dashboard'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            const Icon(Icons.point_of_sale),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Punto de venta · $branchName',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (pos.hasPendingPayment)
            IconButton(
              tooltip: 'Pago pendiente',
              onPressed: () => context.go('/app/pos/checkout'),
              icon: const Icon(Icons.schedule, color: AppColors.warning),
            ),
          TextButton.icon(
            onPressed: () => context.go('/app/pos/tickets'),
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: const Text('Tickets', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: () => context.go(
              pos.shiftOpen ? '/app/pos/shifts/close' : '/app/pos/shifts/open',
            ),
            icon: Icon(
              pos.shiftOpen ? Icons.lock_clock : Icons.lock_open,
              color: Colors.white,
            ),
            label: Text(
              pos.shiftOpen ? 'Cerrar turno' : 'Abrir turno',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: child,
    );
  }
}
