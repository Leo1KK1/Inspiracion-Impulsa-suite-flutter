import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../data/models/purchasing_models.dart';
import '../controllers/purchasing_controller.dart';
import '../widgets/purchase_order_status_badge.dart';

class PurchaseOrdersPage extends StatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage> {
  String _query = '';
  PurchaseOrderStatus? _status;

  @override
  void initState() {
    super.initState();
    final purchasing = context.read<PurchasingController>();
    if (purchasing.status == PurchasingStatus.idle) purchasing.load();
    final inventory = context.read<InventoryController>();
    if (inventory.status == InventoryStatus.idle) inventory.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PurchasingController>();
    if (controller.status == PurchasingStatus.loading &&
        controller.orders.isEmpty) {
      return const AppLoadingState(message: 'Cargando órdenes…');
    }
    if (controller.status == PurchasingStatus.error) {
      return AppErrorState(
        message: controller.errorMessage ?? 'No fue posible cargar órdenes.',
        onRetry: () => controller.load(force: true),
      );
    }
    final query = _query.trim().toLowerCase();
    final orders = controller.orders
        .where((order) {
          return (query.isEmpty ||
                  order.folio.toLowerCase().contains(query) ||
                  order.supplier.toLowerCase().contains(query)) &&
              (_status == null || order.status == _status);
        })
        .toList(growable: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Órdenes de compra',
            subtitle: 'Ciclo real de borrador, envío y recepción.',
            actions: [
              FilledButton.icon(
                onPressed: controller.saving
                    ? null
                    : () => _showOrderForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Nueva orden'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 340,
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar folio o proveedor…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<PurchaseOrderStatus?>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    for (final status in PurchaseOrderStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.apiValue),
                      ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const OperationalEmptyState(
              title: 'Sin órdenes',
              message: 'No hay órdenes con los filtros seleccionados.',
            )
          else
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Folio')),
                    DataColumn(label: Text('Proveedor')),
                    DataColumn(label: Text('Sucursal')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Creación')),
                    DataColumn(label: Text('Partidas'), numeric: true),
                    DataColumn(label: Text('Total'), numeric: true),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final order in orders)
                      DataRow(
                        cells: [
                          DataCell(Text(order.folio)),
                          DataCell(Text(order.supplier)),
                          DataCell(Text(order.branchName)),
                          DataCell(
                            PurchaseOrderStatusBadge(status: order.status),
                          ),
                          DataCell(Text(AppFormatters.date(order.createdAt))),
                          DataCell(Text('${order.itemsCount}')),
                          DataCell(Text(AppFormatters.currency(order.total))),
                          DataCell(
                            IconButton(
                              onPressed: () => context.go(
                                '/app/admin/purchasing/orders/${order.id}',
                              ),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showOrderForm(BuildContext context) async {
    final purchasing = context.read<PurchasingController>();
    final inventory = context.read<InventoryController>();
    final suppliers = purchasing.suppliers
        .where((item) => item.active)
        .toList();
    final products = inventory.products.where((item) => item.isActive).toList();
    if (suppliers.isEmpty || products.isEmpty) {
      _error(
        context,
        'Se necesita al menos un proveedor activo y un producto activo.',
      );
      return;
    }
    String supplierId = suppliers.first.id;
    final notes = TextEditingController();
    final lines = <_OrderLineDraft>[
      _OrderLineDraft(productId: products.first.id),
    ];
    final key = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva orden de compra'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 620),
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: supplierId,
                      decoration: const InputDecoration(labelText: 'Proveedor'),
                      items: [
                        for (final supplier in suppliers)
                          DropdownMenuItem(
                            value: supplier.id,
                            child: Text(supplier.name),
                          ),
                      ],
                      onChanged: (value) => setDialogState(
                        () => supplierId = value ?? supplierId,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notas'),
                    ),
                    const SizedBox(height: 16),
                    for (var index = 0; index < lines.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: lines[index].productId,
                                decoration: const InputDecoration(
                                  labelText: 'Producto',
                                ),
                                items: [
                                  for (final product in products)
                                    DropdownMenuItem(
                                      value: product.id,
                                      child: Text(product.name),
                                    ),
                                ],
                                onChanged: (value) => setDialogState(
                                  () => lines[index].productId =
                                      value ?? lines[index].productId,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: lines[index].quantity,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad',
                                ),
                                validator: _positiveInteger,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: lines[index].cost,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Costo',
                                ),
                                validator: _nonNegative,
                              ),
                            ),
                            if (lines.length > 1)
                              IconButton(
                                onPressed: () => setDialogState(() {
                                  lines.removeAt(index).dispose();
                                }),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setDialogState(
                          () => lines.add(
                            _OrderLineDraft(productId: products.first.id),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar partida'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                Navigator.pop(dialogContext, {
                  'supplierId': supplierId,
                  if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
                  'items': [
                    for (final line in lines)
                      {
                        'productId': line.productId,
                        'quantityOrdered': int.parse(line.quantity.text),
                        'unitCost': double.parse(line.cost.text),
                      },
                  ],
                });
              },
              child: const Text('Crear borrador'),
            ),
          ],
        ),
      ),
    );
    notes.dispose();
    for (final line in lines) {
      line.dispose();
    }
    if (payload == null || !context.mounted) return;
    final ok = await purchasing.createOrder(payload);
    if (!context.mounted) return;
    if (ok) {
      AppSuccessFeedback.show(context, 'Orden creada como borrador.');
    } else {
      _error(context, purchasing.errorMessage);
    }
  }

  static String? _positiveInteger(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number <= 0 ? 'Entero > 0' : null;
  }

  static String? _nonNegative(String? value) {
    final number = double.tryParse(value ?? '');
    return number == null || number < 0 ? 'Valor inválido' : null;
  }

  static void _error(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'No fue posible guardar la orden.')),
    );
  }
}

class _OrderLineDraft {
  _OrderLineDraft({required this.productId});

  String productId;
  final quantity = TextEditingController(text: '1');
  final cost = TextEditingController(text: '0');

  void dispose() {
    quantity.dispose();
    cost.dispose();
  }
}
