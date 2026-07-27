import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/stock_status_badge.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    if (inventory.status == InventoryStatus.idle) {
      Future.microtask(inventory.load);
      return const AppLoadingState(message: 'Cargando producto…');
    }
    final product = inventory.products
        .where((item) => item.id == productId)
        .firstOrNull;
    if (product == null) {
      return OperationalEmptyState(
        title: 'Producto no encontrado',
        message: 'El producto solicitado no existe en el catálogo mock.',
        actionLabel: 'Volver a productos',
        onAction: () => context.go('/app/admin/inventory/products'),
      );
    }
    const movements = [
      ('Hoy 13:22', 'Salida por venta', -48, 'Carlos R.'),
      ('Ayer 11:05', 'Entrada por compra', 120, 'Sofía M.'),
      ('18 Sep 09:41', 'Ajuste de inventario', -5, 'María L.'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: product.name,
            subtitle: '${product.sku} · ${product.category}',
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/app/admin/inventory/products'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Productos'),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width < 800 ? 1 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.2,
            children: [
              MetricCard(
                label: 'Stock actual',
                value: '${product.stock} ${product.unit}',
                detail: 'Mínimo ${product.minStock}',
                icon: Icons.inventory_2_outlined,
              ),
              MetricCard(
                label: 'Costo unitario',
                value: AppFormatters.currency(product.cost),
                icon: Icons.payments_outlined,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Precio de venta',
                value: AppFormatters.currency(product.price),
                detail:
                    'Margen ${((product.price - product.cost) / product.price * 100).toStringAsFixed(1)}%',
                icon: Icons.sell_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Movimientos recientes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      StockStatusBadge(
                        stock: product.stock,
                        minimum: product.minStock,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final movement in movements)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: movement.$3 > 0
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.warning.withValues(alpha: 0.12),
                        child: Icon(
                          movement.$3 > 0 ? Icons.south_west : Icons.north_east,
                          color: movement.$3 > 0
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      title: Text(movement.$2),
                      subtitle: Text('${movement.$1} · ${movement.$4}'),
                      trailing: Text(
                        '${movement.$3 > 0 ? '+' : ''}${movement.$3}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
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
}
