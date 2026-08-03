import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../restaurant_floor/data/models/restaurant_models.dart';
import '../../../restaurant_floor/presentation/widgets/table_status.dart';
import '../controllers/waiter_controller.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WaiterController>().loadOrder(widget.orderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterController>();
    if (waiter.loadingOrder && waiter.selectedOrder == null) {
      return const AppLoadingState(message: 'Consultando la comanda real…');
    }
    final order = waiter.selectedOrder;
    if (order == null) {
      return AppErrorState(
        message: waiter.errorMessage ?? 'No fue posible consultar la comanda.',
        onRetry: () => waiter.loadOrder(widget.orderId),
      );
    }
    final tableId = order.tableSession?.tableId;
    final completed = order.items
        .where(
          (item) =>
              item.status == KitchenItemStatus.ready ||
              item.status == KitchenItemStatus.delivered ||
              item.status == KitchenItemStatus.cancelled,
        )
        .length;
    final progress = order.items.isEmpty ? 0.0 : completed / order.items.length;
    return RefreshIndicator(
      onRefresh: () => waiter.loadOrder(widget.orderId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Volver',
                      onPressed: () => tableId == null
                          ? context.go('/app/restaurant/waiter')
                          : context.go(
                              '/app/restaurant/waiter/tables/$tableId',
                            ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      order.folio,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    KitchenOrderStatusBadge(status: order.status),
                    Text('${order.elapsedMinutes} min'),
                    IconButton.outlined(
                      tooltip: 'Actualizar comanda',
                      onPressed: waiter.loadingOrder
                          ? null
                          : () => waiter.loadOrder(widget.orderId),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (waiter.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    color: AppColors.destructive.withValues(alpha: 0.08),
                    child: Text(
                      waiter.errorMessage!,
                      style: const TextStyle(color: AppColors.destructive),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppCard(
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      Text(order.tableLabel),
                      Text(
                        'Mesero: ${order.waiterUser?.fullName ?? order.waiterUserId}',
                      ),
                      Text('Creada: ${_dateTime(order.createdAt)}'),
                      Text('Actualizada: ${_dateTime(order.updatedAt)}'),
                      Text('Total: ${AppFormatters.currency(order.total)}'),
                      if (order.notes?.isNotEmpty == true)
                        Text('Notas: ${order.notes}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Progreso de partidas',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Text('$completed de ${order.items.length} resueltas'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (order.items.isEmpty)
                  const OperationalEmptyState(
                    title: 'Sin partidas',
                    message: 'La comanda no contiene productos.',
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth >= 850 ? 3 : 1,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: constraints.maxWidth >= 850
                            ? 1.25
                            : 2.7,
                      ),
                      itemCount: order.items.length,
                      itemBuilder: (context, index) =>
                          _ItemCard(item: order.items[index]),
                    ),
                  ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (order.status == KitchenOrderStatus.pending)
                      FilledButton.icon(
                        onPressed: waiter.saving || tableId == null
                            ? null
                            : () async {
                                final success = await waiter.sendExistingOrder(
                                  tableId,
                                  order.id,
                                );
                                if (success) await waiter.loadOrder(order.id);
                              },
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar a cocina'),
                      ),
                    if (order.status == KitchenOrderStatus.ready)
                      FilledButton.icon(
                        onPressed: waiter.saving
                            ? null
                            : () => waiter.updateOrderStatus(
                                order.id,
                                KitchenOrderStatus.delivered,
                                tableId: tableId,
                              ),
                        icon: const Icon(Icons.delivery_dining_outlined),
                        label: const Text('Marcar entregada'),
                      ),
                    if (order.status != KitchenOrderStatus.delivered &&
                        order.status != KitchenOrderStatus.cancelled)
                      OutlinedButton.icon(
                        onPressed: waiter.saving
                            ? null
                            : () =>
                                  _cancelOrder(context, waiter, order, tableId),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancelar comanda'),
                      ),
                    if (tableId != null)
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '/app/restaurant/waiter/tables/$tableId',
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva comanda'),
                      ),
                    if (tableId != null)
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                          '/app/restaurant/waiter/split-bill/$tableId',
                        ),
                        icon: const Icon(Icons.call_split),
                        label: const Text('Dividir cuenta'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder(
    BuildContext context,
    WaiterController waiter,
    KitchenOrder order,
    String? tableId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar comanda'),
        content: const Text(
          'El backend cancelará la comanda y liberará sus reservas de inventario.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar comanda'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await waiter.updateOrderStatus(
      order.id,
      KitchenOrderStatus.cancelled,
      tableId: tableId,
    );
    await waiter.loadOrder(order.id);
  }

  String _dateTime(DateTime? value) => value == null
      ? 'Sin fecha'
      : DateFormat('dd/MM/yyyy HH:mm', 'es_MX').format(value);
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final KitchenOrderItem item;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.quantity} × ${item.productName}',
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(kitchenItemStatusLabel(item.status)),
        Text(AppFormatters.currency(item.lineTotal)),
        if (item.notes?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(item.notes!),
          ),
        ],
      ],
    ),
  );
}
