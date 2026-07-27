import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
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
    if (controller.status == InventoryStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    final session = context.watch<TenantSessionController>().session;
    if (inventory.status == InventoryStatus.loading &&
        inventory.products.isEmpty) {
      return const AppLoadingState(message: 'Cargando inventario…');
    }
    if (inventory.status == InventoryStatus.error) {
      return AppErrorState(
        message: inventory.errorMessage ?? 'No fue posible cargar inventario.',
        onRetry: () => inventory.load(force: true),
      );
    }
    final stockUnits = inventory.stock.fold<int>(
      0,
      (total, item) => total + item.stockOnHand,
    );
    final reserved = inventory.stock.fold<int>(
      0,
      (total, item) => total + item.reservedStock,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Inventario',
            subtitle: 'Existencias reales de la sucursal activa.',
            branch: session?.activeBranchName,
            actions: [
              OutlinedButton.icon(
                onPressed: inventory.status == InventoryStatus.loading
                    ? null
                    : () => inventory.load(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width < 800 ? 1 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.15,
            children: [
              MetricCard(
                label: 'Productos de catálogo',
                value: '${inventory.products.length}',
                icon: Icons.inventory_2_outlined,
              ),
              MetricCard(
                label: 'Unidades en existencia',
                value: '$stockUnits',
                icon: Icons.warehouse_outlined,
                color: AppColors.success,
              ),
              MetricCard(
                label: 'Unidades reservadas',
                value: '$reserved',
                icon: Icons.lock_clock_outlined,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Alertas',
                value: '${inventory.alerts.length}',
                detail: 'Stock bajo o agotado',
                icon: Icons.warning_amber_outlined,
                color: AppColors.destructive,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final alerts = _Alerts(inventory: inventory);
              final movements = _Movements(inventory: inventory);
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [alerts, const SizedBox(height: 14), movements],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: alerts),
                  const SizedBox(width: 14),
                  Expanded(child: movements),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Alerts extends StatelessWidget {
  const _Alerts({required this.inventory});

  final InventoryController inventory;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alertas activas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (inventory.alerts.isEmpty)
            const Text('No hay alertas para la sucursal activa.')
          else
            for (final item in inventory.alerts.take(6))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.productName),
                subtitle: Text(item.sku),
                trailing: AppBadge(
                  label: '${item.stockOnHand} / mín. ${item.minStock}',
                  color: item.stockOnHand <= 0
                      ? AppColors.destructive
                      : AppColors.warning,
                ),
              ),
        ],
      ),
    ),
  );
}

class _Movements extends StatelessWidget {
  const _Movements({required this.inventory});

  final InventoryController inventory;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Movimientos recientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (inventory.movements.isEmpty)
            const Text('No hay movimientos registrados.')
          else
            for (final movement in inventory.movements.take(6))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(movement.productName),
                subtitle: Text(movement.type),
                trailing: Text(
                  '${movement.quantityDelta > 0 ? '+' : ''}${movement.quantityDelta}',
                  style: TextStyle(
                    color: movement.quantityDelta >= 0
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}
