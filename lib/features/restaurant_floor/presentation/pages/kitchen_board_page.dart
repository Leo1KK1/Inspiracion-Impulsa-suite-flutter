import 'dart:async';

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

class _KitchenBoardPageState extends State<KitchenBoardPage>
    with WidgetsBindingObserver {
  Timer? _poller;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<RestaurantController>();
      controller.loadKitchenOrders().whenComplete(() {
        if (mounted) _startPolling();
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (_visible) {
      _startPolling();
      context.read<RestaurantController>().loadKitchenOrders(force: true);
    } else {
      _poller?.cancel();
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_visible || !mounted) return;
      final controller = context.read<RestaurantController>();
      if (!controller.loadingKitchen && !controller.saving) {
        controller.loadKitchenOrders(force: true);
      }
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<RestaurantController>();
    if (restaurant.loadingKitchen && restaurant.kitchenOrders.isEmpty) {
      return const AppLoadingState(message: 'Cargando comandas reales…');
    }
    if (restaurant.errorMessage != null && restaurant.kitchenOrders.isEmpty) {
      return AppErrorState(
        message: restaurant.errorMessage!,
        onRetry: () => restaurant.loadKitchenOrders(force: true),
      );
    }
    final orders = restaurant.kitchenOrders;
    final urgent = orders.where((order) => order.urgent).length;
    final statuses = restaurant.kitchenStatusFilter == null
        ? const [
            KitchenOrderStatus.pending,
            KitchenOrderStatus.inPreparation,
            KitchenOrderStatus.ready,
          ]
        : [restaurant.kitchenStatusFilter!];
    return RefreshIndicator(
      onRefresh: () => restaurant.loadKitchenOrders(force: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Tablero de cocina',
              subtitle:
                  'Estados por platillo. Actualización automática cada 20 segundos mientras la app está activa.',
              actions: [
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<KitchenOrderStatus?>(
                    initialValue: restaurant.kitchenStatusFilter,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Activas'),
                      ),
                      for (final status in KitchenOrderStatus.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(kitchenOrderStatusLabel(status)),
                        ),
                    ],
                    onChanged: restaurant.saving
                        ? null
                        : restaurant.setKitchenStatus,
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Actualizar comandas',
                  onPressed: restaurant.loadingKitchen
                      ? null
                      : () => restaurant.loadKitchenOrders(force: true),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (restaurant.errorMessage != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  tileColor: AppColors.destructive.withValues(alpha: 0.08),
                  leading: const Icon(
                    Icons.error_outline,
                    color: AppColors.destructive,
                  ),
                  title: Text(restaurant.errorMessage!),
                ),
              ),
            ],
            if (urgent > 0) ...[
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  tileColor: AppColors.destructive.withValues(alpha: 0.08),
                  leading: const Icon(
                    Icons.warning_amber,
                    color: AppColors.destructive,
                  ),
                  title: Text('$urgent comandas superan 20 minutos'),
                  subtitle: const Text(
                    'La antigüedad se calcula desde createdAt del backend.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (orders.isEmpty)
              OperationalEmptyState(
                title: 'Sin comandas',
                message: restaurant.kitchenStatusFilter == null
                    ? 'No hay comandas activas en cocina.'
                    : 'No hay comandas con el estado seleccionado.',
                actionLabel: 'Actualizar',
                onAction: () => restaurant.loadKitchenOrders(force: true),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 720) {
                    return Column(
                      children: [
                        for (final status in statuses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              height: 520,
                              child: _KitchenColumn(
                                status: status,
                                orders: orders
                                    .where((order) => order.status == status)
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                  return SizedBox(
                    height: 650,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final status in statuses)
                          SizedBox(
                            width: 340,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _KitchenColumn(
                                status: status,
                                orders: orders
                                    .where((order) => order.status == status)
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _KitchenColumn extends StatelessWidget {
  const _KitchenColumn({required this.status, required this.orders});

  final KitchenOrderStatus status;
  final List<KitchenOrder> orders;

  @override
  Widget build(BuildContext context) => Card(
    color: kitchenOrderStatusColor(status).withValues(alpha: 0.04),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: kitchenOrderStatusColor(status)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  kitchenOrderStatusLabel(status),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              AppBadge(label: '${orders.length}'),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('Sin comandas'))
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) =>
                        _KitchenOrderCard(order: orders[index]),
                  ),
          ),
        ],
      ),
    ),
  );

  IconData _statusIcon(KitchenOrderStatus status) => switch (status) {
    KitchenOrderStatus.pending => Icons.notifications_active_outlined,
    KitchenOrderStatus.inPreparation => Icons.soup_kitchen_outlined,
    KitchenOrderStatus.ready => Icons.check_circle_outline,
    KitchenOrderStatus.delivered => Icons.delivery_dining_outlined,
    KitchenOrderStatus.cancelled => Icons.cancel_outlined,
  };
}

class _KitchenOrderCard extends StatelessWidget {
  const _KitchenOrderCard({required this.order});

  final KitchenOrder order;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RestaurantController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.folio,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppBadge(
                  label: '${order.elapsedMinutes} MIN',
                  color: order.urgent
                      ? AppColors.destructive
                      : AppColors.tenantAccent,
                ),
              ],
            ),
            Text(order.tableLabel),
            if (order.waiterUser != null)
              Text(
                order.waiterUser!.fullName,
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                ),
              ),
            if (order.notes?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Nota: ${order.notes}',
                  style: const TextStyle(color: AppColors.warning),
                ),
              ),
            const Divider(),
            for (final item in order.items)
              _KitchenItemRow(
                order: order,
                item: item,
                disabled: controller.saving,
              ),
          ],
        ),
      ),
    );
  }
}

class _KitchenItemRow extends StatelessWidget {
  const _KitchenItemRow({
    required this.order,
    required this.item,
    required this.disabled,
  });

  final KitchenOrder order;
  final KitchenOrderItem item;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.quantity}× ${item.productName}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            kitchenItemStatusLabel(item.status),
            style: TextStyle(
              color: kitchenOrderStatusColor(
                KitchenOrderStatus.fromApi(item.status.apiValue),
              ),
              fontSize: 12,
            ),
          ),
          if (item.notes?.isNotEmpty == true)
            Text(
              item.notes!,
              style: const TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          if (next != null) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: disabled
                      ? null
                      : () => context
                            .read<RestaurantController>()
                            .updateKitchenItemStatus(order, item, next),
                  icon: const Icon(Icons.arrow_forward, size: 17),
                  label: Text(_actionLabel(next)),
                ),
                TextButton.icon(
                  onPressed: disabled
                      ? null
                      : () => context
                            .read<RestaurantController>()
                            .updateKitchenItemStatus(
                              order,
                              item,
                              KitchenItemStatus.cancelled,
                            ),
                  icon: const Icon(Icons.cancel_outlined, size: 17),
                  label: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  KitchenItemStatus? _nextStatus(KitchenItemStatus status) => switch (status) {
    KitchenItemStatus.pending => KitchenItemStatus.inPreparation,
    KitchenItemStatus.inPreparation => KitchenItemStatus.ready,
    KitchenItemStatus.ready => KitchenItemStatus.delivered,
    KitchenItemStatus.delivered || KitchenItemStatus.cancelled => null,
  };

  String _actionLabel(KitchenItemStatus status) => switch (status) {
    KitchenItemStatus.inPreparation => 'Preparar',
    KitchenItemStatus.ready => 'Marcar listo',
    KitchenItemStatus.delivered => 'Entregar',
    _ => 'Actualizar',
  };
}
