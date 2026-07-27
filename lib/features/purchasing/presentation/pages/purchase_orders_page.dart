import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
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
    final controller = context.read<PurchasingController>();
    if (controller.status == PurchasingStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PurchasingController>();
    if (controller.status == PurchasingStatus.loading) {
      return const AppLoadingState(message: 'Cargando órdenes…');
    }
    if (controller.status == PurchasingStatus.error) {
      return AppErrorState(
        message: controller.errorMessage!,
        onRetry: controller.load,
      );
    }
    final orders = controller.orders.where((order) {
      final matchesQuery =
          order.folio.toLowerCase().contains(_query.toLowerCase()) ||
          order.supplier.toLowerCase().contains(_query.toLowerCase());
      return matchesQuery && (_status == null || order.status == _status);
    }).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Órdenes de compra',
            subtitle: 'Crea, aprueba y recibe mercancía de proveedores.',
            actions: [
              FilledButton.icon(
                onPressed: () => _showOrderForm(context),
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
                width: 200,
                child: DropdownButtonFormField<PurchaseOrderStatus?>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    for (final status in PurchaseOrderStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            OperationalEmptyState(
              title: 'Sin órdenes',
              message: 'No hay órdenes con los filtros seleccionados.',
              actionLabel: 'Limpiar filtros',
              onAction: () => setState(() {
                _query = '';
                _status = null;
              }),
            )
          else
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Folio')),
                    DataColumn(label: Text('Proveedor')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Creación')),
                    DataColumn(label: Text('Entrega')),
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
                          DataCell(
                            PurchaseOrderStatusBadge(status: order.status),
                          ),
                          DataCell(Text(AppFormatters.date(order.createdAt))),
                          DataCell(
                            Text(AppFormatters.date(order.expectedDate)),
                          ),
                          DataCell(Text('${order.items}')),
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
    final controller = context.read<PurchasingController>();
    String? supplier;
    final total = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nueva orden de compra'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: supplier,
                      decoration: const InputDecoration(labelText: 'Proveedor'),
                      items: [
                        for (final item in controller.suppliers)
                          DropdownMenuItem(
                            value: item.name,
                            child: Text(item.name),
                          ),
                      ],
                      validator: (value) =>
                          value == null ? 'Selecciona un proveedor.' : null,
                      onChanged: (value) =>
                          setDialogState(() => supplier = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: total,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total estimado',
                      ),
                      validator: (value) =>
                          (double.tryParse(value ?? '') ?? 0) <= 0
                          ? 'Ingresa un monto válido.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notas'),
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
                if (!formKey.currentState!.validate()) return;
                controller.addOrder(
                  PurchaseOrder(
                    id: 'po-${controller.orders.length + 1}',
                    folio:
                        'OC-2026-${(controller.orders.length + 47).toString().padLeft(4, '0')}',
                    supplier: supplier!,
                    status: PurchaseOrderStatus.draft,
                    createdAt: DateTime.now(),
                    expectedDate: DateTime.now().add(const Duration(days: 7)),
                    items: 1,
                    total: double.parse(total.text),
                    notes: notes.text,
                    createdBy: 'M. López',
                  ),
                );
                Navigator.pop(dialogContext);
                AppSuccessFeedback.show(context, 'Orden creada como borrador.');
              },
              child: const Text('Crear orden'),
            ),
          ],
        ),
      ),
    );
    total.dispose();
    notes.dispose();
  }
}
