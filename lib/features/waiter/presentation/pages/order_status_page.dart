import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../data/models/waiter_models.dart';
import '../controllers/waiter_controller.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  late Future<List<ComandaItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<WaiterController>().getOrderItems(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ComandaItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingState(message: 'Consultando la comanda…');
        }
        if (snapshot.hasError) {
          return AppErrorState(
            message: 'No fue posible consultar la comanda.',
            onRetry: () => setState(
              () => _future = context.read<WaiterController>().getOrderItems(
                widget.orderId,
              ),
            ),
          );
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const OperationalEmptyState(
            title: 'La comanda no tiene productos',
            message: 'Agrega productos desde la sesión de mesa.',
          );
        }
        return _OrderStatusContent(orderId: widget.orderId, items: items);
      },
    );
  }
}

class _OrderStatusContent extends StatelessWidget {
  const _OrderStatusContent({required this.orderId, required this.items});

  final String orderId;
  final List<ComandaItem> items;

  @override
  Widget build(BuildContext context) {
    final ready = items
        .where(
          (item) =>
              item.status == ComandaItemStatus.ready ||
              item.status == ComandaItemStatus.served,
        )
        .length;
    final stations = <String, List<ComandaItem>>{};
    for (final item in items) {
      stations.putIfAbsent(item.station, () => []).add(item);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/app/restaurant/waiter'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Comanda $orderId',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const AppBadge(
                    label: '18 MIN · EN PREPARACIÓN',
                    color: AppColors.warning,
                    icon: Icons.timer_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                color: AppColors.warning.withValues(alpha: 0.08),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Esta comanda superó 15 minutos. Cocina caliente sigue preparando dos partidas.',
                      ),
                    ),
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
                          'Progreso de la comanda',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text('$ready de ${items.length} listos'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: ready / items.length,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: columns == 3 ? 1.15 : 2.4,
                    children: [
                      for (final entry in stations.entries)
                        _StationCard(station: entry.key, items: entry.value),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _KitchenTimeline(items: items),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/app/restaurant/waiter/tables/TBL-08'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva comanda'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.go('/app/restaurant/waiter/split-bill/TBL-08'),
                    icon: const Icon(Icons.call_split),
                    label: const Text('Dividir cuenta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.items});

  final String station;
  final List<ComandaItem> items;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(station, style: Theme.of(context).textTheme.titleMedium),
        const Divider(height: 22),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity} × ${item.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ItemStatusBadge(status: item.status),
                  ],
                ),
                if (item.notes case final notes?)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(notes, style: const TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _ItemStatusBadge extends StatelessWidget {
  const _ItemStatusBadge({required this.status});

  final ComandaItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ComandaItemStatus.queued => ('EN COLA', AppColors.mutedForeground),
      ComandaItemStatus.inPreparation => ('PREPARANDO', AppColors.warning),
      ComandaItemStatus.ready => ('LISTO', AppColors.success),
      ComandaItemStatus.served => ('SERVIDO', AppColors.primary),
    };
    return AppBadge(label: label, color: color);
  }
}

class _KitchenTimeline extends StatelessWidget {
  const _KitchenTimeline({required this.items});

  final List<ComandaItem> items;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Comanda enviada', '19:12', true),
      ('Cocina confirmó', '19:14', true),
      ('Preparación en curso', '19:18', true),
      ('Todos los productos listos', 'Pendiente', false),
      ('Entrega en mesa', 'Pendiente', false),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seguimiento de cocina',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: steps[i].$3
                            ? AppColors.tenantAccent
                            : Colors.white,
                        border: Border.all(color: AppColors.tenantAccent),
                        boxShadow: i == 2
                            ? [
                                BoxShadow(
                                  color: AppColors.tenantAccent.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(width: 2, height: 32, color: AppColors.border),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(steps[i].$1)),
                Text(
                  steps[i].$2,
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
