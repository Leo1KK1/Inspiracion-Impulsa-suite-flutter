import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../waiter/data/models/waiter_models.dart';
import '../../data/models/restaurant_models.dart';
import '../controllers/restaurant_controller.dart';
import '../widgets/table_status.dart';

class TableDetailPage extends StatefulWidget {
  const TableDetailPage({super.key, required this.tableId});

  final String tableId;

  @override
  State<TableDetailPage> createState() => _TableDetailPageState();
}

class _TableDetailPageState extends State<TableDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RestaurantController>().loadTableDetail(widget.tableId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<RestaurantController>();
    if (restaurant.loadingDetail && restaurant.selectedTable == null) {
      return const AppLoadingState(message: 'Cargando mesa real…');
    }
    final table = restaurant.selectedTable;
    if (table == null) {
      return AppErrorState(
        message: restaurant.errorMessage ?? 'La mesa solicitada no existe.',
        onRetry: () => restaurant.loadTableDetail(widget.tableId),
      );
    }
    final session = table.activeSession;
    final orders = restaurant.selectedTableOrders;
    final total = orders
        .where((order) => order.status != KitchenOrderStatus.cancelled)
        .fold<double>(0, (sum, order) => sum + order.total);
    final items = [
      for (final order in orders)
        for (final item in order.items) (order: order, item: item),
    ];
    return RefreshIndicator(
      onRefresh: () => restaurant.loadTableDetail(widget.tableId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: table.name,
              subtitle:
                  '${table.area?.name ?? 'Sin área'} · Capacidad ${table.capacity}',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/app/restaurant/floor'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Plano'),
                ),
                TableStatusBadge(status: table.status),
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
            const SizedBox(height: 18),
            if (session == null)
              _ClosedTableActions(
                table: table,
                saving: restaurant.saving,
                onOpen: () => _showOpenSession(context, table),
              )
            else ...[
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width < 780 ? 1 : 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.15,
                children: [
                  MetricCard(
                    label: 'Comensales',
                    value: '${session.dinerCount}',
                    icon: Icons.groups_outlined,
                  ),
                  MetricCard(
                    label: 'Tiempo abierta',
                    value: '${session.openedMinutes} min',
                    icon: Icons.schedule,
                  ),
                  MetricCard(
                    label: 'Comandas',
                    value: '${orders.length}',
                    icon: Icons.receipt_long,
                  ),
                  MetricCard(
                    label: 'Cuenta actual',
                    value: AppFormatters.currency(total),
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SessionCard(
                session: session,
                onAssign: () => _showAssignWaiter(context, table),
                onOperate: () =>
                    context.go('/app/restaurant/waiter/tables/${table.id}'),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const OperationalEmptyState(
                  title: 'Sin comandas',
                  message:
                      'La sesión está abierta, pero aún no tiene partidas.',
                )
              else
                _ItemsTable(items: items),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text('Total de partidas activas'),
                      const Spacer(),
                      Text(
                        AppFormatters.currency(total),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showOpenSession(
    BuildContext context,
    RestaurantTable table,
  ) async {
    final result = await showDialog<OpenTableSessionRequest>(
      context: context,
      builder: (_) => _OpenSessionDialog(table: table),
    );
    if (result == null || !context.mounted) return;
    final success = await context.read<RestaurantController>().openSession(
      table.id,
      result,
    );
    if (success && context.mounted) {
      AppSuccessFeedback.show(context, 'Mesa abierta correctamente.');
    }
  }

  Future<void> _showAssignWaiter(
    BuildContext context,
    RestaurantTable table,
  ) async {
    final waiterId = await showDialog<String>(
      context: context,
      builder: (_) => const _AssignWaiterDialog(),
    );
    if (waiterId == null || !context.mounted) return;
    final success = await context.read<RestaurantController>().assignWaiter(
      table.id,
      waiterId,
    );
    if (success && context.mounted) {
      AppSuccessFeedback.show(context, 'Mesero asignado correctamente.');
    }
  }
}

class _ClosedTableActions extends StatelessWidget {
  const _ClosedTableActions({
    required this.table,
    required this.saving,
    required this.onOpen,
  });

  final RestaurantTable table;
  final bool saving;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Esta mesa no tiene una sesión abierta. La apertura será validada por el backend para evitar duplicados.',
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed:
                table.status == RestaurantTableStatus.available && !saving
                ? onOpen
                : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Abrir mesa'),
          ),
        ],
      ),
    ),
  );
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onAssign,
    required this.onOperate,
  });

  final TableSession session;
  final VoidCallback onAssign;
  final VoidCallback onOperate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Mesero: ${session.waiterUser?.fullName ?? session.waiterUserId}',
          ),
          if (session.customerName?.isNotEmpty == true)
            Text('Cliente: ${session.customerName}'),
          if (session.notes?.isNotEmpty == true)
            Text('Notas: ${session.notes}'),
          OutlinedButton.icon(
            onPressed: onAssign,
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Asignar mesero'),
          ),
          FilledButton.icon(
            onPressed: onOperate,
            icon: const Icon(Icons.room_service_outlined),
            label: const Text('Operar mesa'),
          ),
        ],
      ),
    ),
  );
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items});

  final List<({KitchenOrder order, KitchenOrderItem item})> items;

  @override
  Widget build(BuildContext context) => Card(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Comanda')),
          DataColumn(label: Text('Producto')),
          DataColumn(label: Text('Cantidad'), numeric: true),
          DataColumn(label: Text('Importe'), numeric: true),
          DataColumn(label: Text('Estado')),
        ],
        rows: [
          for (final row in items)
            DataRow(
              cells: [
                DataCell(Text(row.order.folio)),
                DataCell(Text(row.item.productName)),
                DataCell(Text('${row.item.quantity}')),
                DataCell(Text(AppFormatters.currency(row.item.lineTotal))),
                DataCell(Text(kitchenItemStatusLabel(row.item.status))),
              ],
            ),
        ],
      ),
    ),
  );
}

class _OpenSessionDialog extends StatefulWidget {
  const _OpenSessionDialog({required this.table});

  final RestaurantTable table;

  @override
  State<_OpenSessionDialog> createState() => _OpenSessionDialogState();
}

class _OpenSessionDialogState extends State<_OpenSessionDialog> {
  final _key = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _notes = TextEditingController();
  int _diners = 1;

  @override
  void dispose() {
    _customer.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Abrir ${widget.table.name}'),
    content: Form(
      key: _key,
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: '1',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Comensales'),
              validator: (value) {
                final diners = int.tryParse(value ?? '');
                if (diners == null || diners < 1 || diners > 50) {
                  return 'Ingresa un valor entre 1 y 50.';
                }
                return null;
              },
              onChanged: (value) => _diners = int.tryParse(value) ?? 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customer,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_key.currentState!.validate()) return;
          Navigator.pop(
            context,
            OpenTableSessionRequest(
              dinerCount: _diners,
              customerName: _customer.text,
              notes: _notes.text,
            ),
          );
        },
        child: const Text('Abrir mesa'),
      ),
    ],
  );
}

class _AssignWaiterDialog extends StatefulWidget {
  const _AssignWaiterDialog();

  @override
  State<_AssignWaiterDialog> createState() => _AssignWaiterDialogState();
}

class _AssignWaiterDialogState extends State<_AssignWaiterDialog> {
  final _key = GlobalKey<FormState>();
  final _id = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Asignar mesero'),
    content: Form(
      key: _key,
      child: TextFormField(
        controller: _id,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'ID del usuario mesero',
          helperText:
              'HU06 no expone un endpoint de catálogo de meseros; usa un ID real.',
        ),
        validator: (value) =>
            value?.trim().isEmpty != false ? 'Ingresa el ID del mesero.' : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_key.currentState!.validate()) {
            Navigator.pop(context, _id.text.trim());
          }
        },
        child: const Text('Asignar'),
      ),
    ],
  );
}
