import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/restaurant_models.dart';
import '../controllers/restaurant_controller.dart';
import '../widgets/table_status.dart';

class KitchenBoardPage extends StatefulWidget {
  const KitchenBoardPage({super.key});

  @override
  State<KitchenBoardPage> createState() => _KitchenBoardPageState();
}

class _KitchenBoardPageState extends State<KitchenBoardPage> {
  RestaurantZone? _zone;

  @override
  void initState() {
    super.initState();
    final controller = context.read<RestaurantController>();
    if (controller.kitchenOrders.isEmpty) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<RestaurantController>();
    if (restaurant.loading) {
      return const AppLoadingState(message: 'Cargando comandas…');
    }
    final orders = restaurant.kitchenOrders
        .where((order) => _zone == null || order.zone == _zone)
        .toList();
    final urgent = orders.where((order) => order.urgent).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Tablero de cocina',
            subtitle: 'Comandas por etapa y actualización en vivo.',
            actions: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<RestaurantZone?>(
                  initialValue: _zone,
                  decoration: const InputDecoration(labelText: 'Zona'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final zone in RestaurantZone.values)
                      DropdownMenuItem(
                        value: zone,
                        child: Text(zoneLabel(zone)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _zone = value),
                ),
              ),
            ],
          ),
          if (urgent > 0) ...[
            const SizedBox(height: 14),
            Card(
              color: AppColors.destructive.withValues(alpha: 0.08),
              child: ListTile(
                leading: const Icon(
                  Icons.warning_amber,
                  color: AppColors.destructive,
                ),
                title: Text('$urgent comandas superan 20 minutos'),
                subtitle: const Text('Prioriza su preparación y entrega.'),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              for (final status in KitchenOrderStatus.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: MetricCard(
                      label: _statusLabel(status),
                      value:
                          '${orders.where((order) => order.status == status).length}',
                      icon: _statusIcon(status),
                      color: _statusColor(status),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 620,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final status in KitchenOrderStatus.values)
                  SizedBox(
                    width: 310,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _KitchenColumn(
                        status: status,
                        orders: orders
                            .where((order) => order.status == status)
                            .toList(),
                        onAdvance: restaurant.advanceKitchenOrder,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(KitchenOrderStatus status) => switch (status) {
    KitchenOrderStatus.newOrder => 'Nuevas',
    KitchenOrderStatus.inPreparation => 'En preparación',
    KitchenOrderStatus.ready => 'Listas',
    KitchenOrderStatus.delivered => 'Entregadas',
  };

  static IconData _statusIcon(KitchenOrderStatus status) => switch (status) {
    KitchenOrderStatus.newOrder => Icons.notifications_active_outlined,
    KitchenOrderStatus.inPreparation => Icons.soup_kitchen_outlined,
    KitchenOrderStatus.ready => Icons.check_circle_outline,
    KitchenOrderStatus.delivered => Icons.delivery_dining_outlined,
  };

  static Color _statusColor(KitchenOrderStatus status) => switch (status) {
    KitchenOrderStatus.newOrder => AppColors.primary,
    KitchenOrderStatus.inPreparation => AppColors.warning,
    KitchenOrderStatus.ready => AppColors.success,
    KitchenOrderStatus.delivered => AppColors.mutedForeground,
  };
}

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({
    required this.status,
    required this.orders,
    required this.onAdvance,
  });
  final KitchenOrderStatus status;
  final List<KitchenOrder> orders;
  final ValueChanged<String> onAdvance;

  @override
  Widget build(BuildContext context) => Card(
    color: _KitchenBoardPageState._statusColor(status).withValues(alpha: 0.04),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_KitchenBoardPageState._statusIcon(status)),
              const SizedBox(width: 7),
              Text(
                _KitchenBoardPageState._statusLabel(status),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              AppBadge(label: '${orders.length}'),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('Sin comandas'))
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _KitchenOrderCard(
                      order: orders[index],
                      onAdvance: onAdvance,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _KitchenOrderCard extends StatelessWidget {
  const _KitchenOrderCard({required this.order, required this.onAdvance});
  final KitchenOrder order;
  final ValueChanged<String> onAdvance;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                order.id,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              AppBadge(
                label: '${order.sentMinutesAgo} MIN',
                color: order.urgent
                    ? AppColors.destructive
                    : AppColors.tenantAccent,
              ),
            ],
          ),
          Text('Mesa ${order.tableNumber} · ${zoneLabel(order.zone)}'),
          Text(
            order.waiterName,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 11,
            ),
          ),
          const Divider(),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}× ${item.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (item.notes != null)
                    Text(
                      item.notes!,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          if (order.status != KitchenOrderStatus.delivered)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => onAdvance(order.id),
                child: Text(_action(order.status)),
              ),
            ),
        ],
      ),
    ),
  );

  String _action(KitchenOrderStatus status) => switch (status) {
    KitchenOrderStatus.newOrder => 'Iniciar',
    KitchenOrderStatus.inPreparation => 'Listo',
    KitchenOrderStatus.ready => 'Entregar',
    KitchenOrderStatus.delivered => 'Entregada',
  };
}
