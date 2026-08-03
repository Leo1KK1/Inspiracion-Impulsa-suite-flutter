import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RestaurantController>().loadTables();
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<RestaurantController>();
    if (restaurant.loadingTables && restaurant.tables.isEmpty) {
      return const AppLoadingState(message: 'Cargando mesas reales…');
    }
    if (restaurant.errorMessage != null && restaurant.tables.isEmpty) {
      return AppErrorState(
        message: restaurant.errorMessage!,
        onRetry: () => restaurant.loadTables(force: true),
      );
    }
    final counts = {
      for (final status in RestaurantTableStatus.values)
        status: restaurant.tables
            .where((table) => table.status == status)
            .length,
    };
    return RefreshIndicator(
      onRefresh: () => restaurant.loadTables(force: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Plano de mesas',
              subtitle:
                  'Estado operativo de la sucursal activa, sincronizado con el backend.',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/app/restaurant/kitchen-board'),
                  icon: const Icon(Icons.soup_kitchen_outlined),
                  label: const Text('Tablero cocina'),
                ),
                IconButton.outlined(
                  tooltip: 'Actualizar mesas',
                  onPressed: restaurant.loadingTables
                      ? null
                      : () => restaurant.loadTables(force: true),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (restaurant.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: restaurant.errorMessage!),
            ],
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
                  value: '${counts[RestaurantTableStatus.available]}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                MetricCard(
                  label: 'Ocupadas',
                  value: '${counts[RestaurantTableStatus.occupied]}',
                  icon: Icons.groups_outlined,
                  color: AppColors.tenantAccent,
                ),
                MetricCard(
                  label: 'Reservadas',
                  value: '${counts[RestaurantTableStatus.reserved]}',
                  icon: Icons.event_seat_outlined,
                  color: const Color(0xFF4F46E5),
                ),
                MetricCard(
                  label: 'Por limpiar',
                  value: '${counts[RestaurantTableStatus.dirty]}',
                  icon: Icons.cleaning_services_outlined,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
            const SizedBox(height: 15),
            _Filters(restaurant: restaurant),
            const SizedBox(height: 15),
            if (restaurant.filteredTables.isEmpty)
              OperationalEmptyState(
                title: 'Sin mesas',
                message: restaurant.tables.isEmpty
                    ? 'El backend no devolvió mesas para esta sucursal.'
                    : 'No hay mesas con los filtros seleccionados.',
                actionLabel: restaurant.tables.isEmpty
                    ? 'Actualizar'
                    : 'Limpiar filtros',
                onAction: restaurant.tables.isEmpty
                    ? () => restaurant.loadTables(force: true)
                    : () {
                        restaurant
                          ..setArea(null)
                          ..setStatus(null);
                      },
              )
            else
              _AreaGrid(restaurant: restaurant),
            const SizedBox(height: 15),
            const _Legend(),
          ],
        ),
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
        width: 220,
        child: DropdownButtonFormField<String?>(
          initialValue: restaurant.areaFilterId,
          decoration: const InputDecoration(labelText: 'Área'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            for (final area in restaurant.areas)
              DropdownMenuItem(value: area.id, child: Text(area.name)),
          ],
          onChanged: restaurant.setArea,
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

class _AreaGrid extends StatelessWidget {
  const _AreaGrid({required this.restaurant});

  final RestaurantController restaurant;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<RestaurantTable>>{};
    for (final table in restaurant.filteredTables) {
      grouped.putIfAbsent(table.area?.name ?? 'Sin área', () => []).add(table);
    }
    return Column(
      children: [
        for (final entry in grouped.entries)
          Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) => GridView.count(
                      crossAxisCount: (constraints.maxWidth / 185)
                          .floor()
                          .clamp(1, 6),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.18,
                      children: [
                        for (final table in entry.value)
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
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});

  final RestaurantTable table;

  @override
  Widget build(BuildContext context) {
    final color = tableStatusColor(table.status);
    return Semantics(
      button: true,
      label: '${table.name}, ${tableStatusLabel(table.status)}',
      child: Material(
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
                    Expanded(
                      child: Text(
                        table.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.circle, color: color, size: 10),
                  ],
                ),
                Text(
                  tableStatusLabel(table.status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text('Capacidad: ${table.capacity}'),
                if (table.activeSession case final session?)
                  Text(
                    '${session.dinerCount} comensales · ${session.openedMinutes} min',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      tileColor: AppColors.destructive.withValues(alpha: 0.08),
      leading: const Icon(Icons.error_outline, color: AppColors.destructive),
      title: Text(message),
    ),
  );
}
