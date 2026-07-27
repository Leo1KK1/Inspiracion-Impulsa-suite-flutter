import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/restaurant_models.dart';
import '../controllers/restaurant_controller.dart';
import '../widgets/table_status.dart';

class RestaurantFloorPage extends StatefulWidget {
  const RestaurantFloorPage({super.key});

  @override
  State<RestaurantFloorPage> createState() => _RestaurantFloorPageState();
}

class _RestaurantFloorPageState extends State<RestaurantFloorPage> {
  @override
  void initState() {
    super.initState();
    final restaurant = context.read<RestaurantController>();
    if (restaurant.tables.isEmpty) restaurant.load();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<RestaurantController>();
    if (restaurant.loading) {
      return const AppLoadingState(message: 'Cargando plano de mesas…');
    }
    final available = restaurant.tables
        .where((table) => table.status == RestaurantTableStatus.available)
        .length;
    final occupied = restaurant.tables
        .where((table) => table.status == RestaurantTableStatus.occupied)
        .length;
    final bill = restaurant.tables
        .where((table) => table.status == RestaurantTableStatus.readyToBill)
        .length;
    final activeTotal = restaurant.tables.fold<double>(
      0,
      (sum, table) => sum + table.total,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Plano de mesas',
            subtitle: 'Supervisión administrativa del piso en tiempo real.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/app/restaurant/kitchen-board'),
                icon: const Icon(Icons.soup_kitchen_outlined),
                label: const Text('Tablero cocina'),
              ),
              FilterChip(
                selected: restaurant.rearrangeMode,
                onSelected: (_) => restaurant.toggleRearrange(),
                avatar: const Icon(Icons.open_with, size: 17),
                label: const Text('Reacomodo de mesas'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: _columns(MediaQuery.sizeOf(context).width),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              MetricCard(
                label: 'Disponibles',
                value: '$available',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
              MetricCard(
                label: 'Ocupadas',
                value: '$occupied',
                icon: Icons.groups_outlined,
                color: AppColors.tenantAccent,
              ),
              MetricCard(
                label: 'Listas para cobrar',
                value: '$bill',
                icon: Icons.payments_outlined,
                color: const Color(0xFF9333EA),
              ),
              MetricCard(
                label: 'Consumo activo',
                value: AppFormatters.compactCurrency(activeTotal),
                icon: Icons.receipt_long_outlined,
              ),
            ],
          ),
          const SizedBox(height: 15),
          _Filters(restaurant: restaurant),
          const SizedBox(height: 15),
          if (restaurant.filteredTables.isEmpty)
            OperationalEmptyState(
              title: 'Sin mesas',
              message: 'No hay mesas con los filtros seleccionados.',
              actionLabel: 'Limpiar filtros',
              onAction: () {
                restaurant
                  ..setZone(null)
                  ..setStatus(null);
              },
            )
          else if (restaurant.rearrangeMode)
            _RearrangeCanvas(restaurant: restaurant)
          else
            _ZoneGrid(restaurant: restaurant),
          const SizedBox(height: 15),
          const _Legend(),
        ],
      ),
    );
  }

  int _columns(double width) => width < 700
      ? 1
      : width < 1280
      ? 2
      : 4;
}

class _Filters extends StatelessWidget {
  const _Filters({required this.restaurant});
  final RestaurantController restaurant;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      SizedBox(
        width: 180,
        child: DropdownButtonFormField<RestaurantZone?>(
          initialValue: restaurant.zoneFilter,
          decoration: const InputDecoration(labelText: 'Zona'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            for (final zone in RestaurantZone.values)
              DropdownMenuItem(value: zone, child: Text(zoneLabel(zone))),
          ],
          onChanged: restaurant.setZone,
        ),
      ),
      SizedBox(
        width: 210,
        child: DropdownButtonFormField<RestaurantTableStatus?>(
          initialValue: restaurant.statusFilter,
          decoration: const InputDecoration(labelText: 'Estado'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todos')),
            for (final status in RestaurantTableStatus.values)
              DropdownMenuItem(
                value: status,
                child: Text(tableStatusLabel(status)),
              ),
          ],
          onChanged: restaurant.setStatus,
        ),
      ),
    ],
  );
}

class _ZoneGrid extends StatelessWidget {
  const _ZoneGrid({required this.restaurant});
  final RestaurantController restaurant;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final zone in RestaurantZone.values)
        if (restaurant.filteredTables.any((table) => table.zone == zone))
          Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zoneLabel(zone),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) => GridView.count(
                      crossAxisCount: (constraints.maxWidth / 185)
                          .floor()
                          .clamp(2, 6),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.18,
                      children: [
                        for (final table in restaurant.filteredTables.where(
                          (table) => table.zone == zone,
                        ))
                          _TableCard(table: table),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    ],
  );
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});
  final RestaurantTable table;

  @override
  Widget build(BuildContext context) {
    final color = tableStatusColor(table.status);
    return Material(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/app/restaurant/floor/${table.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${table.number}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  Icon(Icons.circle, color: color, size: 10),
                ],
              ),
              Text(
                tableStatusLabel(table.status),
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text('${table.guestCount}/${table.capacity} personas'),
              if (table.openedMinutes != null)
                Text(
                  '${table.openedMinutes} min · ${AppFormatters.currency(table.total)}',
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RearrangeCanvas extends StatelessWidget {
  const _RearrangeCanvas({required this.restaurant});
  final RestaurantController restaurant;

  @override
  Widget build(BuildContext context) => Card(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 920,
        height: 540,
        child: Stack(
          children: [
            for (final table in restaurant.filteredTables)
              Positioned(
                left: restaurant.positions[table.id]?.dx ?? 0,
                top: restaurant.positions[table.id]?.dy ?? 0,
                child: GestureDetector(
                  onPanUpdate: (details) =>
                      restaurant.moveTable(table.id, details.delta),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: _TableCard(table: table),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final status in RestaurantTableStatus.values)
        TableStatusBadge(status: status),
    ],
  );
}
