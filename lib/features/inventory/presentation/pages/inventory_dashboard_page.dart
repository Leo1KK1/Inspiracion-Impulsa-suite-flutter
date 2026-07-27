import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../controllers/inventory_controller.dart';

class InventoryDashboardPage extends StatefulWidget {
  const InventoryDashboardPage({super.key});

  @override
  State<InventoryDashboardPage> createState() => _InventoryDashboardPageState();
}

class _InventoryDashboardPageState extends State<InventoryDashboardPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<InventoryController>();
    if (controller.status == InventoryStatus.idle) {
      controller.load(
        branchId: context.read<TenantSessionController>().activeBranchId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    if (inventory.status == InventoryStatus.loading) {
      return const AppLoadingState(message: 'Cargando inventario…');
    }
    if (inventory.status == InventoryStatus.error) {
      return AppErrorState(
        message: inventory.errorMessage!,
        onRetry: inventory.load,
      );
    }
    final value = inventory.products.fold<double>(
      0,
      (sum, product) => sum + product.cost * product.stock,
    );
    final low = inventory.products
        .where((product) => product.stock < product.minStock)
        .length;
    final empty = inventory.products
        .where((product) => product.stock == 0)
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dashboard de inventario',
            subtitle: 'Estado y movimientos de la sucursal activa.',
            actions: [
              OutlinedButton.icon(
                onPressed: inventory.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _columns(MediaQuery.sizeOf(context).width),
            crossAxisSpacing: 13,
            mainAxisSpacing: 13,
            childAspectRatio: 2.15,
            children: [
              MetricCard(
                label: 'Total SKUs',
                value: '${inventory.products.length}',
                detail: '${inventory.categories.length} categorías',
                icon: Icons.inventory_2_outlined,
              ),
              MetricCard(
                label: 'Valor del inventario',
                value: '\$${(value / 1000).toStringAsFixed(1)}K',
                detail: 'Costo de reposición',
                icon: Icons.payments_outlined,
                color: AppColors.tenantAccent,
              ),
              MetricCard(
                label: 'Stock bajo',
                value: '$low',
                detail: 'Por debajo del mínimo',
                icon: Icons.warning_amber_outlined,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Sin stock',
                value: '$empty',
                detail: 'Requieren orden urgente',
                icon: Icons.inventory_outlined,
                color: AppColors.destructive,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = const _MovementChart();
              final alerts = _CriticalAlerts(inventory: inventory);
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [chart, const SizedBox(height: 16), alerts],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 3, child: _MovementChart()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: alerts),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  int _columns(double width) {
    if (width < 700) return 1;
    if (width < 1280) return 2;
    return 4;
  }
}

class _MovementChart extends StatelessWidget {
  const _MovementChart();

  @override
  Widget build(BuildContext context) {
    const incoming = [284.0, 310.0, 195.0, 420.0];
    const outgoing = [198.0, 231.0, 248.0, 279.0];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entradas vs salidas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(),
                    rightTitles: AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < incoming.length; index++)
                      BarChartGroupData(
                        x: index,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: incoming[index],
                            color: AppColors.tenantAccent,
                            width: 16,
                          ),
                          BarChartRodData(
                            toY: outgoing[index],
                            color: AppColors.primary,
                            width: 16,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CriticalAlerts extends StatelessWidget {
  const _CriticalAlerts({required this.inventory});
  final InventoryController inventory;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Alertas críticas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/app/admin/inventory/alerts'),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          for (final alert in inventory.alerts.take(4))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x1ADC2626),
                child: Icon(Icons.warning_amber, color: AppColors.destructive),
              ),
              title: Text(alert.product.name),
              subtitle: Text(
                '${alert.product.stock} / mín. ${alert.product.minStock} ${alert.product.unit}',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
        ],
      ),
    ),
  );
}
