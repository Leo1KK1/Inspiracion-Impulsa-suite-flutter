import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/inventory_models.dart';
import '../controllers/inventory_controller.dart';

class InventoryAlertsPage extends StatefulWidget {
  const InventoryAlertsPage({super.key});

  @override
  State<InventoryAlertsPage> createState() => _InventoryAlertsPageState();
}

class _InventoryAlertsPageState extends State<InventoryAlertsPage> {
  StockSeverity? _severity;

  @override
  void initState() {
    super.initState();
    final controller = context.read<InventoryController>();
    if (controller.status == InventoryStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    if (inventory.status == InventoryStatus.loading) {
      return const AppLoadingState(message: 'Cargando alertas…');
    }
    final alerts = inventory.alerts
        .where((alert) => _severity == null || alert.severity == _severity)
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Alertas de stock bajo',
            subtitle: 'Productos que requieren reposición o atención.',
            actions: [
              OutlinedButton.icon(
                onPressed: inventory.load,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _severity == null,
                onSelected: (_) => setState(() => _severity = null),
              ),
              for (final severity in StockSeverity.values)
                ChoiceChip(
                  label: Text(_label(severity)),
                  selected: _severity == severity,
                  onSelected: (_) => setState(() => _severity = severity),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            OperationalEmptyState(
              title: 'Sin alertas',
              message: 'No hay productos con esta severidad.',
              actionLabel: 'Ver todas',
              onAction: () => setState(() => _severity = null),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth < 800 ? 1 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth < 800 ? 1.8 : 1.65,
                ),
                itemCount: alerts.length,
                itemBuilder: (context, index) =>
                    _AlertCard(alert: alerts[index]),
              ),
            ),
        ],
      ),
    );
  }

  String _label(StockSeverity severity) => switch (severity) {
    StockSeverity.outOfStock => 'Sin stock',
    StockSeverity.critical => 'Crítico',
    StockSeverity.low => 'Stock bajo',
    StockSeverity.ok => 'OK',
  };
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final StockAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      StockSeverity.outOfStock => AppColors.destructive,
      StockSeverity.critical => const Color(0xFFF97316),
      StockSeverity.low => AppColors.warning,
      StockSeverity.ok => AppColors.success,
    };
    final percentage = alert.product.stock / alert.maxStock;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(Icons.warning_amber, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${alert.product.sku} · ${alert.product.category}',
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AppBadge(label: _label(alert.severity), color: color),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage.clamp(0, 1),
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 7),
            Text(
              '${alert.product.stock} / ${alert.maxStock} ${alert.product.unit} · mín. ${alert.product.minStock}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Último movimiento: ${alert.lastMovement}\nSugerencia: ${alert.suggestedOrder} ${alert.product.unit}',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go(
                    '/app/admin/purchasing/orders?product=${alert.product.id}',
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Crear orden'),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _label(StockSeverity severity) => switch (severity) {
    StockSeverity.outOfStock => 'SIN STOCK',
    StockSeverity.critical => 'CRÍTICO',
    StockSeverity.low => 'STOCK BAJO',
    StockSeverity.ok => 'OK',
  };
}
