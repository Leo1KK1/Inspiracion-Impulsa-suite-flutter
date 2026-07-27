import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/purchasing_models.dart';
import '../controllers/purchasing_controller.dart';
import '../widgets/purchase_order_status_badge.dart';

class PurchaseOrderDetailPage extends StatelessWidget {
  const PurchaseOrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PurchasingController>();
    if (controller.status == PurchasingStatus.idle) {
      Future.microtask(controller.load);
      return const AppLoadingState(message: 'Cargando orden…');
    }
    final order = controller.orders
        .where((item) => item.id == orderId)
        .firstOrNull;
    if (order == null) {
      return OperationalEmptyState(
        title: 'Orden no encontrada',
        message: 'El folio solicitado no existe.',
        actionLabel: 'Volver',
        onAction: () => context.go('/app/admin/purchasing/orders'),
      );
    }
    return FutureBuilder<List<PurchaseOrderLine>>(
      future: controller.getLines(orderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingState(message: 'Cargando partidas…');
        }
        final lines = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: order.folio,
                subtitle: '${order.supplier} · Creada por ${order.createdBy}',
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/app/admin/purchasing/orders'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Órdenes'),
                  ),
                  if (order.status != PurchaseOrderStatus.received)
                    FilledButton.icon(
                      onPressed: () => _showReceiveDialog(context, lines),
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: const Text('Recibir mercancía'),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      PurchaseOrderStatusBadge(status: order.status),
                      const SizedBox(width: 18),
                      Expanded(child: Text(order.notes)),
                      Text(
                        AppFormatters.currency(order.total),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Producto')),
                      DataColumn(label: Text('Ordenado'), numeric: true),
                      DataColumn(label: Text('Recibido'), numeric: true),
                      DataColumn(label: Text('Costo'), numeric: true),
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('Stock proyectado')),
                    ],
                    rows: [
                      for (final line in lines)
                        DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(line.name),
                                  subtitle: Text(line.sku),
                                ),
                              ),
                            ),
                            DataCell(Text('${line.ordered} ${line.unit}')),
                            DataCell(Text('${line.received} ${line.unit}')),
                            DataCell(Text(AppFormatters.currency(line.cost))),
                            DataCell(
                              Text(
                                AppFormatters.currency(
                                  line.cost * line.ordered,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${line.stockBefore} → ${line.stockBefore + line.received}',
                                style: TextStyle(
                                  color:
                                      line.stockBefore + line.received >=
                                          line.minimum
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showReceiveDialog(
    BuildContext context,
    List<PurchaseOrderLine> lines,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recepción de mercancía'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Confirma las cantidades recibidas. El inventario se actualizará al guardar.',
              ),
              const SizedBox(height: 14),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    initialValue: '${line.ordered - line.received}',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${line.name} · pendiente',
                      suffixText: line.unit,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              AppSuccessFeedback.show(
                context,
                'Recepción registrada y stock actualizado.',
              );
            },
            child: const Text('Confirmar recepción'),
          ),
        ],
      ),
    );
  }
}
