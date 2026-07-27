import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
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
  RestaurantZone? _zone;
  RestaurantTableStatus? _status;

  @override
  void initState() {
    super.initState();
    final controller = context.read<RestaurantController>();
    if (controller.tables.isEmpty) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TenantSessionController>();
    if (session.activeBranchId == null) {
      return const BranchContextRequiredState();
    }
    final restaurant = context.watch<RestaurantController>();
    if (restaurant.loading) {
      return const AppLoadingState(message: 'Cargando mesas…');
    }
    final tables = restaurant.tables.where((table) {
      return (_zone == null || table.zone == _zone) &&
          (_status == null || table.status == _status);
    }).toList();
    final available = restaurant.tables
        .where((table) => table.status == RestaurantTableStatus.available)
        .length;
    final occupied = restaurant.tables
        .where((table) => table.status == RestaurantTableStatus.occupied)
        .length;
    final ready = restaurant.tables
        .where((table) => table.status == RestaurantTableStatus.readyToBill)
        .length;
    return SingleChildScrollView(
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
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width < 700 ? 1 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
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
                value: '$ready',
                icon: Icons.payments_outlined,
                color: const Color(0xFF9333EA),
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
                  label: const Text('Todas las zonas'),
                  selected: _zone == null,
                  onSelected: (_) => setState(() => _zone = null),
                ),
                const SizedBox(width: 8),
                for (final zone in RestaurantZone.values) ...[
                  ChoiceChip(
                    label: Text(zoneLabel(zone)),
                    selected: _zone == zone,
                    onSelected: (_) => setState(() => _zone = zone),
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
              for (final status in [
                RestaurantTableStatus.available,
                RestaurantTableStatus.occupied,
                RestaurantTableStatus.readyToBill,
              ])
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
              message: 'No hay mesas con los filtros seleccionados.',
              actionLabel: 'Limpiar filtros',
              onAction: () => setState(() {
                _zone = null;
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
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }
}

class _WaiterTableCard extends StatelessWidget {
  const _WaiterTableCard({required this.table});
  final RestaurantTable table;

  @override
  Widget build(BuildContext context) {
    final color = tableStatusColor(table.status);
    final action = switch (table.status) {
      RestaurantTableStatus.available => 'Abrir mesa',
      RestaurantTableStatus.readyToBill => 'Cobrar mesa',
      _ => 'Ir a mesa',
    };
    return Card(
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
                  children: [
                    Row(
                      children: [
                        Text(
                          '${table.number}',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const Spacer(),
                        TableStatusBadge(status: table.status),
                      ],
                    ),
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
                    if (table.total > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppFormatters.currency(table.total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
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
    );
  }
}
