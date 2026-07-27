import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../controllers/inventory_controller.dart';

class InventoryAlertsPage extends StatefulWidget {
  const InventoryAlertsPage({super.key});

  @override
  State<InventoryAlertsPage> createState() => _InventoryAlertsPageState();
}

class _InventoryAlertsPageState extends State<InventoryAlertsPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<InventoryController>();
    if (controller.status == InventoryStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    final branch = context.watch<TenantSessionController>().session;
    if (inventory.status == InventoryStatus.loading &&
        inventory.products.isEmpty) {
      return const AppLoadingState(message: 'Cargando alertas…');
    }
    if (inventory.status == InventoryStatus.error) {
      return AppErrorState(
        message: inventory.errorMessage ?? 'No fue posible cargar alertas.',
        onRetry: () => inventory.load(force: true),
      );
    }
    final out = inventory.alerts.where((item) => item.stockOnHand <= 0).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Alertas de inventario',
            subtitle: 'Semáforo calculado por el backend.',
            branch: branch?.activeBranchName,
            actions: [
              OutlinedButton.icon(
                onPressed: () => inventory.load(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppBadge(label: '$out agotados', color: AppColors.destructive),
              AppBadge(
                label: '${inventory.alerts.length - out} bajo mínimo',
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (inventory.alerts.isEmpty)
            const OperationalEmptyState(
              title: 'Inventario saludable',
              message: 'No hay alertas activas en la sucursal.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth < 700 ? 1 : 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.2,
                ),
                itemCount: inventory.alerts.length,
                itemBuilder: (context, index) {
                  final item = inventory.alerts[index];
                  final critical = item.stockOnHand <= 0;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                (critical
                                        ? AppColors.destructive
                                        : AppColors.warning)
                                    .withValues(alpha: 0.12),
                            child: Icon(
                              Icons.warning_amber_outlined,
                              color: critical
                                  ? AppColors.destructive
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.productName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(item.sku),
                                Text(
                                  'Existencia ${item.stockOnHand} · mínimo ${item.minStock} · disponible ${item.availableStock}',
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.go(
                              '/app/admin/inventory/products/${item.productId}',
                            ),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
