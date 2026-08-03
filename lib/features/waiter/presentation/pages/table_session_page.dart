import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../pos/presentation/controllers/pos_controller.dart';
import '../../../restaurant_floor/data/models/restaurant_models.dart';
import '../../../restaurant_floor/presentation/widgets/table_status.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../../data/models/waiter_models.dart';
import '../controllers/waiter_controller.dart';
import '../widgets/order_composer_panel.dart';

class TableSessionPage extends StatefulWidget {
  const TableSessionPage({super.key, required this.tableId});

  final String tableId;

  @override
  State<TableSessionPage> createState() => _TableSessionPageState();
}

class _TableSessionPageState extends State<TableSessionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final waiter = context.read<WaiterController>();
      final session = context.read<TenantSessionController>();
      final pos = context.read<PosController>();
      waiter.loadTable(widget.tableId).whenComplete(() {
        if (!mounted) return;
        if (session.hasAnyRole(const ['OWNER', 'MANAGER', 'CASHIER'])) {
          pos.load(branchId: session.activeBranchId, force: true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterController>();
    if (waiter.loadingTable && waiter.activeTable == null) {
      return const AppLoadingState(message: 'Cargando sesión de mesa…');
    }
    final table = waiter.activeTable;
    if (table == null) {
      return AppErrorState(
        message: waiter.errorMessage ?? 'No fue posible consultar la mesa.',
        onRetry: () => waiter.loadTable(widget.tableId),
      );
    }
    final activeSession = table.activeSession;
    if (activeSession == null) {
      return _OpenTableView(
        table: table,
        errorMessage: waiter.errorMessage,
        saving: waiter.saving,
        onOpen: () => _openTable(context, table),
      );
    }
    final compact = MediaQuery.sizeOf(context).width < 980;
    final catalog = _MenuCatalog(waiter: waiter);
    final composer = OrderComposerPanel(
      controller: waiter,
      tableId: widget.tableId,
    );
    final session = context.watch<TenantSessionController>();
    final pos = context.watch<PosController>();
    final canCheckout = session.hasAnyRole(const [
      'OWNER',
      'MANAGER',
      'CASHIER',
    ]);
    return Column(
      children: [
        Material(
          color: Colors.white,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Volver a mesas',
                  onPressed: () => context.go('/app/restaurant/waiter'),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(table.name, style: Theme.of(context).textTheme.titleLarge),
                TableStatusBadge(status: table.status),
                AppBadge(
                  label:
                      '${activeSession.dinerCount} comensales · ${activeSession.openedMinutes} min',
                ),
                OutlinedButton.icon(
                  onPressed: waiter.tableOrders.isEmpty
                      ? null
                      : () => context.go(
                          '/app/restaurant/waiter/split-bill/${widget.tableId}',
                        ),
                  icon: const Icon(Icons.call_split),
                  label: const Text('Dividir cuenta'),
                ),
                FilledButton.icon(
                  onPressed:
                      !canCheckout ||
                          waiter.tableOrders.isEmpty ||
                          waiter.saving
                      ? null
                      : () => _checkout(context, table, pos),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                    pos.activeShift == null
                        ? 'Cobrar sin turno'
                        : 'Cobrar mesa',
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Actualizar mesa',
                  onPressed: waiter.loadingTable
                      ? null
                      : () => waiter.loadTable(widget.tableId),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
        if (waiter.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: AppColors.destructive.withValues(alpha: 0.08),
            child: Text(
              waiter.errorMessage!,
              style: const TextStyle(color: AppColors.destructive),
            ),
          ),
        if (activeSession.notes?.isNotEmpty == true)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: AppColors.warning.withValues(alpha: 0.1),
            child: Text('Notas de mesa: ${activeSession.notes}'),
          ),
        if (waiter.tableOrders.isNotEmpty)
          _ExistingOrders(
            tableId: widget.tableId,
            orders: waiter.tableOrders,
            saving: waiter.saving,
            canInspect: session.hasAnyRole(const [
              'OWNER',
              'MANAGER',
              'WAITER',
            ]),
          ),
        Expanded(
          child: compact
              ? Column(
                  children: [
                    Expanded(child: catalog),
                    Material(
                      elevation: 14,
                      child: ExpansionTile(
                        initiallyExpanded: waiter.order.isNotEmpty,
                        title: Text(
                          'Nueva comanda · ${waiter.order.length} partidas · '
                          '${AppFormatters.currency(waiter.total)}',
                        ),
                        children: [SizedBox(height: 470, child: composer)],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: catalog),
                    SizedBox(width: 370, child: composer),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _openTable(BuildContext context, RestaurantTable table) async {
    final request = await showDialog<OpenTableSessionRequest>(
      context: context,
      builder: (_) => _OpenSessionDialog(table: table),
    );
    if (request == null || !context.mounted) return;
    final success = await context.read<WaiterController>().openSession(
      table.id,
      request,
    );
    if (success && context.mounted) {
      AppSuccessFeedback.show(context, 'Mesa abierta correctamente.');
    }
  }

  Future<void> _checkout(
    BuildContext context,
    RestaurantTable table,
    PosController pos,
  ) async {
    final shift = pos.activeShift;
    if (shift == null) {
      final openShift = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Se requiere turno de caja'),
          content: const Text(
            'El backend exige un turno OPEN del usuario autenticado en esta sucursal antes de cobrar la mesa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Abrir turno'),
            ),
          ],
        ),
      );
      if (openShift == true && context.mounted) {
        context.go('/app/pos/shifts/open');
      }
      return;
    }
    final request = await showDialog<RestaurantCheckoutRequest>(
      context: context,
      builder: (_) => _CheckoutDialog(
        cashShiftId: shift.id,
        total: context.read<WaiterController>().tableOrders.fold(
          0,
          (sum, order) => order.status == KitchenOrderStatus.cancelled
              ? sum
              : sum + order.total,
        ),
      ),
    );
    if (request == null || !context.mounted) return;
    final waiter = context.read<WaiterController>();
    final success = await waiter.checkout(table.id, request);
    if (!success || !context.mounted) return;
    await pos.load(branchId: pos.branchId, force: true);
    if (!context.mounted) return;
    final result = waiter.checkoutResult;
    final continueToPos = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mesa cobrada'),
        content: Text(
          result == null
              ? 'El checkout terminó correctamente.'
              : '${result.message}\n\nVenta: ${result.sale.folio}\n'
                    'Total: ${AppFormatters.currency(result.sale.total)}'
                    '${result.cardPaymentIntent == null ? '' : '\nIntent de tarjeta: ${result.cardPaymentIntent!.intentId}'}',
        ),
        actions: [
          if (request.paymentMethod != RestaurantPaymentMethod.cash)
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuar en POS'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    context.go(
      continueToPos == true ? '/app/pos/checkout' : '/app/restaurant/waiter',
    );
  }
}

class _OpenTableView extends StatelessWidget {
  const _OpenTableView({
    required this.table,
    required this.errorMessage,
    required this.saving,
    required this.onOpen,
  });

  final RestaurantTable table;
  final String? errorMessage;
  final bool saving;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.table_restaurant_outlined,
                  size: 64,
                  color: tableStatusColor(table.status),
                ),
                const SizedBox(height: 12),
                Text(
                  table.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                TableStatusBadge(status: table.status),
                const SizedBox(height: 14),
                Text(
                  table.status == RestaurantTableStatus.available
                      ? 'La mesa está disponible. El backend rechazará una segunda apertura concurrente.'
                      : 'La mesa no tiene sesión OPEN y su estado actual no permite abrirla desde este flujo.',
                  textAlign: TextAlign.center,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.destructive),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/app/restaurant/waiter'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          table.status == RestaurantTableStatus.available &&
                              !saving
                          ? onOpen
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Abrir mesa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ExistingOrders extends StatelessWidget {
  const _ExistingOrders({
    required this.tableId,
    required this.orders,
    required this.saving,
    required this.canInspect,
  });

  final String tableId;
  final List<KitchenOrder> orders;
  final bool saving;
  final bool canInspect;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 74,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      scrollDirection: Axis.horizontal,
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final order = orders[index];
        return ActionChip(
          avatar: Icon(
            order.status == KitchenOrderStatus.ready
                ? Icons.check_circle
                : Icons.receipt_long_outlined,
            size: 18,
          ),
          label: Text(
            '${order.folio} · ${kitchenOrderStatusLabel(order.status)}',
          ),
          onPressed: saving || !canInspect
              ? null
              : () => context.go('/app/restaurant/waiter/orders/${order.id}'),
        );
      },
    ),
  );
}

class _MenuCatalog extends StatelessWidget {
  const _MenuCatalog({required this.waiter});

  final WaiterController waiter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        TextField(
          onChanged: waiter.setQuery,
          decoration: const InputDecoration(
            labelText: 'Buscar en el menú',
            hintText: 'Nombre, SKU o código de barras',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final category in waiter.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: waiter.category == category,
                    onSelected: (_) => waiter.setCategory(category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (waiter.loadingMenu)
          const LinearProgressIndicator()
        else
          const SizedBox(height: 4),
        Expanded(
          child: waiter.filteredMenu.isEmpty
              ? OperationalEmptyState(
                  title: 'Sin productos',
                  message: waiter.query.trim().isEmpty
                      ? 'No hay productos con existencia disponible.'
                      : 'No hay resultados para la búsqueda.',
                  actionLabel: 'Recargar menú',
                  onAction: () => waiter.loadMenu(force: true),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (constraints.maxWidth / 220)
                          .floor()
                          .clamp(1, 4),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.08,
                    ),
                    itemCount: waiter.filteredMenu.length,
                    itemBuilder: (context, index) {
                      final product = waiter.filteredMenu[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: waiter.saving || !product.available
                              ? null
                              : () => waiter.add(product),
                          child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppBadge(
                                  label: product.category,
                                  color: AppColors.tenantAccent,
                                ),
                                const Spacer(),
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${product.availableStock} ${product.unitName} disponibles',
                                  style: const TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        AppFormatters.currency(product.price),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                    const CircleAvatar(
                                      radius: 18,
                                      child: Icon(Icons.add, size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
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
  final _formKey = GlobalKey<FormState>();
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
      key: _formKey,
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
                final number = int.tryParse(value ?? '');
                return number == null || number < 1 || number > 50
                    ? 'Ingresa un valor entre 1 y 50.'
                    : null;
              },
              onChanged: (value) => _diners = int.tryParse(value) ?? 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customer,
              decoration: const InputDecoration(
                labelText: 'Cliente (opcional)',
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
          if (!_formKey.currentState!.validate()) return;
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

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog({required this.cashShiftId, required this.total});

  final String cashShiftId;
  final double total;

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cash = TextEditingController();
  final _notes = TextEditingController();
  RestaurantPaymentMethod _method = RestaurantPaymentMethod.cash;
  RestaurantTableStatus _nextStatus = RestaurantTableStatus.dirty;

  @override
  void dispose() {
    _cash.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Cobrar y cerrar mesa'),
    content: Form(
      key: _formKey,
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ${AppFormatters.currency(widget.total)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<RestaurantPaymentMethod>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Forma de pago'),
                items: [
                  for (final method in RestaurantPaymentMethod.values)
                    DropdownMenuItem(value: method, child: Text(method.label)),
                ],
                onChanged: (value) => setState(() {
                  _method = value ?? RestaurantPaymentMethod.cash;
                }),
              ),
              if (_method != RestaurantPaymentMethod.card) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cash,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _method == RestaurantPaymentMethod.cash
                        ? 'Efectivo recibido'
                        : 'Parte en efectivo',
                    prefixText: r'$ ',
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount < 0) {
                      return 'Ingresa un monto válido.';
                    }
                    if (_method == RestaurantPaymentMethod.cash &&
                        amount < widget.total) {
                      return 'El efectivo no cubre el total.';
                    }
                    if (_method == RestaurantPaymentMethod.mixed &&
                        (amount <= 0 || amount >= widget.total)) {
                      return 'Debe ser mayor a 0 y menor al total.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<RestaurantTableStatus>(
                initialValue: _nextStatus,
                decoration: const InputDecoration(
                  labelText: 'Estado posterior de la mesa',
                ),
                items: const [
                  DropdownMenuItem(
                    value: RestaurantTableStatus.dirty,
                    child: Text('Por limpiar'),
                  ),
                  DropdownMenuItem(
                    value: RestaurantTableStatus.available,
                    child: Text('Disponible'),
                  ),
                ],
                onChanged: (value) =>
                    _nextStatus = value ?? RestaurantTableStatus.dirty,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
              ),
              if (_method != RestaurantPaymentMethod.cash) ...[
                const SizedBox(height: 12),
                const Text(
                  'El backend generará un intent de tarjeta. Los pendientes se recuperan en el checkout POS.',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
              ],
            ],
          ),
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
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            RestaurantCheckoutRequest(
              cashShiftId: widget.cashShiftId,
              paymentMethod: _method,
              cashReceived: _method == RestaurantPaymentMethod.card
                  ? null
                  : double.tryParse(_cash.text),
              nextTableStatus: _nextStatus,
              notes: _notes.text,
            ),
          );
        },
        child: const Text('Confirmar cobro'),
      ),
    ],
  );
}
