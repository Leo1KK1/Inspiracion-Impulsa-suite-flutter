import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/data/models/tenant_session.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../controllers/tenant_admin_controller.dart';

class TenantDashboardPage extends StatefulWidget {
  const TenantDashboardPage({super.key});

  @override
  State<TenantDashboardPage> createState() => _TenantDashboardPageState();
}

class _TenantDashboardPageState extends State<TenantDashboardPage> {
  @override
  void initState() {
    super.initState();
    final session = context.read<TenantSessionController>();
    if (session.hasAnyRole(const ['OWNER', 'MANAGER'])) {
      final controller = context.read<TenantAdminController>();
      if (controller.status == TenantAdminStatus.idle) controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<TenantAdminController>();
    final session = context.watch<TenantSessionController>().session;
    final canViewAdmin = context
        .watch<TenantSessionController>()
        .hasAnyRole(const ['OWNER', 'MANAGER']);
    if (!canViewAdmin) {
      return _OperationalLanding(session: session);
    }
    if (admin.status == TenantAdminStatus.loading && admin.dashboard == null) {
      return const AppLoadingState(message: 'Cargando resumen del negocio…');
    }
    if (admin.status == TenantAdminStatus.error && admin.dashboard == null) {
      return AppErrorState(
        message: admin.errorMessage ?? 'No fue posible cargar el resumen.',
        onRetry: () => admin.load(force: true),
      );
    }
    final metrics = admin.dashboard;
    if (metrics == null) {
      return const OperationalEmptyState(
        title: 'Sin información',
        message: 'El servidor no devolvió métricas administrativas.',
      );
    }
    final firstName = session?.userName.split(' ').first ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Hola, $firstName',
            subtitle: 'Resumen administrativo entregado por el backend.',
            branch: session?.activeBranchName,
            role: session?.roleCodes.firstOrNull,
            actions: [
              OutlinedButton.icon(
                onPressed: admin.status == TenantAdminStatus.loading
                    ? null
                    : () => admin.load(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            crossAxisCount: _columns(MediaQuery.sizeOf(context).width),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.25,
            children: [
              MetricCard(
                label: 'Sucursales',
                value: '${metrics.totalBranches}',
                detail: '${metrics.activeBranches} activas',
                icon: Icons.store_mall_directory_outlined,
                color: AppColors.tenantAccent,
              ),
              MetricCard(
                label: 'Empleados',
                value: '${metrics.totalEmployees}',
                detail: '${metrics.activeEmployees} activos',
                icon: Icons.groups_outlined,
                color: AppColors.success,
              ),
              MetricCard(
                label: 'Roles',
                value: '${metrics.totalRoles}',
                detail: 'Configurados en el tenant',
                icon: Icons.admin_panel_settings_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _columns(double width) {
    if (width < 720) return 1;
    if (width < 1100) return 2;
    return 3;
  }
}

class _OperationalLanding extends StatelessWidget {
  const _OperationalLanding({required this.session});

  final TenantSession? session;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Hola, ${session?.userName ?? ''}',
          subtitle: 'Tu sesión está lista para operar.',
          branch: session?.activeBranchName,
          role: session?.roleCodes.firstOrNull,
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.tenantAccent,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Acceso validado para ${session?.tenantName ?? 'el tenant'} en ${session?.activeBranchName ?? 'la sucursal asignada'}.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
