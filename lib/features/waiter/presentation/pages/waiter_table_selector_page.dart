import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../restaurant_floor/data/models/restaurant_models.dart';
import '../../../restaurant_floor/presentation/controllers/restaurant_controller.dart';
import '../../../restaurant_floor/presentation/widgets/table_status.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';

class WaiterTableSelectorPage extends StatefulWidget {
  const WaiterTableSelectorPage({super.key});

  @override
  State<WaiterTableSelectorPage> createState() =>
      _WaiterTableSelectorPageState();
}

class _WaiterTableSelectorPageState extends State<WaiterTableSelectorPage> {
  String? _areaId;
  RestaurantTableStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RestaurantController>().loadTables();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TenantSessionController>();
    if (session.activeBranchId == null) {
      return const BranchContextRequiredState();
    }
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
    final tables = restaurant.tables
        .where((table) {
          return (_areaId == null || table.areaId == _areaId) &&
              (_status == null || table.status == _status);
        })
        .toList(growable: false);
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: _greeting(),
              subtitle:
                  'Selecciona una mesa para iniciar o continuar el servicio.',
              branch: session.session?.activeBranchName,
              role: session.roleCodes.firstOrNull,
              actions: [
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
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width < 700 ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                for (final status in RestaurantTableStatus.values)
                  MetricCard(
                    label: tableStatusLabel(status),
                    value: '${counts[status]}',
                    icon: _statusIcon(status),
                    color: tableStatusColor(status),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('Todas las áreas'),
                    selected: _areaId == null,
                    onSelected: (_) => setState(() => _areaId = null),
                  ),
                  const SizedBox(width: 8),
                  for (final area in restaurant.areas) ...[
                    ChoiceChip(
                      label: Text(area.name),
                      selected: _areaId == area.id,
                      onSelected: (_) => setState(() => _areaId = area.id),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos los estados'),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                for (final status in RestaurantTableStatus.values)
                  FilterChip(
                    label: Text(tableStatusLabel(status)),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            if (tables.isEmpty)
              OperationalEmptyState(
                title: 'Sin mesas',
                message: restaurant.tables.isEmpty
                    ? 'El backend no devolvió mesas para esta sucursal.'
                    : 'No hay mesas con los filtros seleccionados.',
                actionLabel: 'Limpiar filtros',
                onAction: () => setState(() {
                  _areaId = null;
                  _status = null;
                }),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: (constraints.maxWidth / 225).floor().clamp(
                      1,
                      5,
                    ),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.08,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) =>
                      _WaiterTableCard(table: tables[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  IconData _statusIcon(RestaurantTableStatus status) => switch (status) {
    RestaurantTableStatus.available => Icons.check_circle_outline,
    RestaurantTableStatus.occupied => Icons.groups_outlined,
    RestaurantTableStatus.reserved => Icons.event_seat_outlined,
    RestaurantTableStatus.dirty => Icons.cleaning_services_outlined,
  };
}

class _WaiterTableCard extends StatelessWidget {
  const _WaiterTableCard({required this.table});

  final RestaurantTable table;

  @override
  Widget build(BuildContext context) {
    final color = tableStatusColor(table.status);
    final action = table.status == RestaurantTableStatus.available
        ? 'Abrir mesa'
        : 'Ver mesa';
    return Semantics(
      button: true,
      label: '${table.name}, ${tableStatusLabel(table.status)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/app/restaurant/waiter/tables/${table.id}'),
          child: Column(
            children: [
              Container(height: 7, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              table.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TableStatusBadge(status: table.status),
                        ],
                      ),
                      Text(table.area?.name ?? 'Sin área'),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.groups_outlined, size: 17),
                          const SizedBox(width: 5),
                          Text('${table.guestCount}/${table.capacity}'),
                          const Spacer(),
                          if (table.openedMinutes != null)
                            Text('${table.openedMinutes} min'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: color),
                          onPressed: () => context.go(
                            '/app/restaurant/waiter/tables/${table.id}',
                          ),
                          child: Text(action),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
