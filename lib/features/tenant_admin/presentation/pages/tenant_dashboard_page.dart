import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../../../../shared/widgets/page_header.dart';

class TenantDashboardPage extends StatelessWidget {
  const TenantDashboardPage({super.key});

  static const hourlySales = [
    3200.0,
    4800.0,
    6200.0,
    7900.0,
    9100.0,
    11800.0,
    13400.0,
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TenantSessionController>().session;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Buenos días, ${session?.userName.split(' ').first ?? ''}',
            subtitle: 'Resumen operativo de tu sucursal activa.',
            branch: session?.activeBranchName,
            role: session?.roleCodes.firstOrNull,
            actions: [
              OutlinedButton.icon(
                onPressed: () {},
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
            childAspectRatio: 2.35,
            children: const [
              MetricCard(
                label: 'Ventas hoy',
                value: r'$55,240',
                detail: '+14.2% vs ayer',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              MetricCard(
                label: 'Tickets / órdenes',
                value: '184',
                detail: '+8 vs ayer',
                icon: Icons.receipt_long_outlined,
              ),
              MetricCard(
                label: 'Clientes atendidos',
                value: '312',
                detail: '+5.1%',
                icon: Icons.groups_outlined,
                color: Color(0xFF7C3AED),
              ),
              MetricCard(
                label: 'Alertas de stock',
                value: '3',
                detail: '2 críticas',
                icon: Icons.warning_amber_outlined,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = _SalesChart(data: hourlySales);
              final activity = const _RecentActivity();
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [chart, const SizedBox(height: 16), activity],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 16),
                  const Expanded(flex: 2, child: _RecentActivity()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  int _columns(double width) {
    if (width < 720) return 1;
    if (width < 1280) return 2;
    return 4;
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.data});
  final List<double> data;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas por hora',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Acumulado del día',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 15000,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                ),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 48),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < data.length; i++)
                        FlSpot(i.toDouble(), data[i]),
                    ],
                    color: AppColors.tenantAccent,
                    barWidth: 3,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.tenantAccent.withValues(alpha: 0.1),
                    ),
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

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('ORD-1842', 'Mesa 08', 1280.0, 'Completado'),
      ('ORD-1841', 'Mostrador', 645.0, 'En proceso'),
      ('ORD-1840', 'Mesa 12', 980.0, 'Completado'),
      ('ORD-1839', 'Delivery', 420.0, 'Preparando'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad reciente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            for (final row in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_outlined, size: 18),
                ),
                title: Text('${row.$1} · ${row.$2}'),
                subtitle: Text(row.$4),
                trailing: Text(
                  AppFormatters.currency(row.$3),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
