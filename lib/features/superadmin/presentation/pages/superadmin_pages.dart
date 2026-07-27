import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/superadmin_models.dart';
import '../controllers/superadmin_controller.dart';

class SuperadminDashboardPage extends StatefulWidget {
  const SuperadminDashboardPage({super.key});

  @override
  State<SuperadminDashboardPage> createState() =>
      _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends State<SuperadminDashboardPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<SuperadminController>();
    if (controller.tenants.isEmpty) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SuperadminController>();
    if (controller.loading) {
      return const AppLoadingState(message: 'Cargando plataforma…');
    }
    if (controller.errorMessage case final message?) {
      return AppErrorState(message: message, onRetry: controller.load);
    }
    final active = controller.tenants
        .where((tenant) => tenant.status == 'ACTIVO')
        .length;
    final revenue = controller.tenants.fold<double>(
      0,
      (sum, tenant) => sum + tenant.monthlyRevenue,
    );
    return _SuperadminPageFrame(
      children: [
        const PageHeader(
          title: 'Resumen de plataforma',
          subtitle: 'Actividad, crecimiento y salud de todos los tenants.',
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth >= 1050 ? 4 : 2,
            childAspectRatio: constraints.maxWidth >= 1050 ? 1.7 : 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              MetricCard(
                label: 'Tenants',
                value: '${controller.tenants.length}',
                detail: '$active activos',
                icon: Icons.business,
              ),
              const MetricCard(
                label: 'Usuarios activos',
                value: '199',
                detail: '+12 este mes',
                icon: Icons.people,
                color: AppColors.tenantAccent,
              ),
              MetricCard(
                label: 'MRR',
                value: AppFormatters.currency(revenue),
                detail: '+8.4% vs. mes anterior',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              const MetricCard(
                label: 'Disponibilidad',
                value: '99.98%',
                detail: 'Servicios saludables',
                icon: Icons.cloud_done,
                color: AppColors.info,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crecimiento de tenants',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 230,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        spots: const [
                          FlSpot(0, 18),
                          FlSpot(1, 22),
                          FlSpot(2, 28),
                          FlSpot(3, 34),
                          FlSpot(4, 41),
                          FlSpot(5, 52),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SuperadminTenantsPage extends StatefulWidget {
  const SuperadminTenantsPage({super.key});

  @override
  State<SuperadminTenantsPage> createState() => _SuperadminTenantsPageState();
}

class _SuperadminTenantsPageState extends State<SuperadminTenantsPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<SuperadminController>();
    if (controller.tenants.isEmpty) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SuperadminController>();
    if (controller.loading) {
      return const AppLoadingState(message: 'Cargando tenants…');
    }
    return _SuperadminPageFrame(
      children: [
        PageHeader(
          title: 'Tenants',
          subtitle: 'Gestiona las organizaciones activas en Impulsa Suite.',
          actions: [
            ElevatedButton.icon(
              onPressed: () =>
                  AppSuccessFeedback.show(context, 'Solicitud de alta creada.'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo tenant'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: controller.setQuery,
          decoration: const InputDecoration(
            hintText: 'Buscar por nombre o identificador…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        if (controller.filteredTenants.isEmpty)
          OperationalEmptyState(
            title: 'No hay tenants que coincidan',
            message: 'Modifica la búsqueda para ver resultados.',
            actionLabel: 'Limpiar búsqueda',
            onAction: () => controller.setQuery(''),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Tenant')),
                  DataColumn(label: Text('Plan')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Sucursales')),
                  DataColumn(label: Text('Usuarios')),
                  DataColumn(label: Text('MRR')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final tenant in controller.filteredTenants)
                    DataRow(
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(tenant.id),
                            ],
                          ),
                        ),
                        DataCell(Text(tenant.plan)),
                        DataCell(_TenantStatus(status: tenant.status)),
                        DataCell(Text('${tenant.branches}')),
                        DataCell(Text('${tenant.users}')),
                        DataCell(
                          Text(AppFormatters.currency(tenant.monthlyRevenue)),
                        ),
                        DataCell(
                          IconButton(
                            tooltip: 'Ver tenant',
                            onPressed: () =>
                                context.go('/superadmin/tenants/${tenant.id}'),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SuperadminTenantDetailPage extends StatelessWidget {
  const SuperadminTenantDetailPage({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SuperadminController>();
    final tenant = controller.tenants
        .where((candidate) => candidate.id == tenantId)
        .firstOrNull;
    if (controller.loading) {
      return const AppLoadingState(message: 'Cargando tenant…');
    }
    if (tenant == null) {
      return AppErrorState(
        message: 'No encontramos el tenant solicitado.',
        onRetry: () => context.go('/superadmin/tenants'),
      );
    }
    return _SuperadminPageFrame(
      children: [
        PageHeader(
          title: tenant.name,
          subtitle: '${tenant.id} · Plan ${tenant.plan}',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _confirmToggle(context, tenant),
              icon: Icon(
                tenant.status == 'SUSPENDIDO'
                    ? Icons.play_arrow
                    : Icons.pause_outlined,
              ),
              label: Text(
                tenant.status == 'SUSPENDIDO'
                    ? 'Reactivar tenant'
                    : 'Suspender tenant',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 250,
              child: MetricCard(
                label: 'Estado',
                value: tenant.status,
                icon: Icons.verified_user_outlined,
                color: tenant.status == 'ACTIVO'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            SizedBox(
              width: 250,
              child: MetricCard(
                label: 'Sucursales',
                value: '${tenant.branches}',
                icon: Icons.store_outlined,
              ),
            ),
            SizedBox(
              width: 250,
              child: MetricCard(
                label: 'Usuarios',
                value: '${tenant.users}',
                icon: Icons.people_outline,
              ),
            ),
            SizedBox(
              width: 250,
              child: MetricCard(
                label: 'Ingreso mensual',
                value: AppFormatters.currency(tenant.monthlyRevenue),
                icon: Icons.payments_outlined,
                color: AppColors.tenantAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actividad reciente',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Icon(Icons.login)),
                title: Text('Inicio de sesión administrativo'),
                subtitle: Text('María López · hace 12 minutos'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Icon(Icons.store)),
                title: Text('Sucursal CDMX Centro actualizada'),
                subtitle: Text('Configuración operativa · ayer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    PlatformTenant tenant,
  ) async {
    final suspend = tenant.status != 'SUSPENDIDO';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(suspend ? 'Suspender tenant' : 'Reactivar tenant'),
        content: Text(
          suspend
              ? 'El acceso operativo quedará bloqueado hasta reactivar la organización.'
              : 'La organización recuperará acceso a sus módulos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<SuperadminController>().toggleTenant(tenant.id);
    AppSuccessFeedback.show(
      context,
      suspend ? 'Tenant suspendido.' : 'Tenant reactivado.',
    );
  }
}

class SuperadminModulePage extends StatelessWidget {
  const SuperadminModulePage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _SuperadminPageFrame(
    children: [
      PageHeader(title: title, subtitle: description),
      const SizedBox(height: 20),
      AppCard(
        child: Row(
          children: [
            CircleAvatar(radius: 28, child: Icon(icon)),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'La referencia React contiene este módulo como estado informativo, sin operaciones ni contrato backend. La ruta se conserva para no romper navegación.',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TenantStatus extends StatelessWidget {
  const _TenantStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ACTIVO' => AppColors.success,
      'SUSPENDIDO' => AppColors.destructive,
      _ => AppColors.warning,
    };
    return AppBadge(label: status, color: color);
  }
}

class _SuperadminPageFrame extends StatelessWidget {
  const _SuperadminPageFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ),
  );
}
