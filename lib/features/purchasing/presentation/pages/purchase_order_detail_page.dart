import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../inventory/presentation/controllers/inventory_controller.dart';
import '../../data/models/purchasing_models.dart';
import '../controllers/purchasing_controller.dart';
import '../widgets/purchase_order_status_badge.dart';

class PurchaseOrderDetailPage extends StatefulWidget {
  const PurchaseOrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<PurchaseOrderDetailPage> createState() =>
      _PurchaseOrderDetailPageState();
}

class _PurchaseOrderDetailPageState extends State<PurchaseOrderDetailPage> {
  late Future<PurchaseOrder?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<PurchasingController>().getOrder(widget.orderId);
  }

  void _reload() {
    setState(() {
      _future = context.read<PurchasingController>().getOrder(
        widget.orderId,
        force: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PurchaseOrder?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AppLoadingState(message: 'Cargando orden…');
        }
        final order = snapshot.data;
        if (order == null) {
          return OperationalEmptyState(
            title: 'Orden no encontrada',
            message:
                context.watch<PurchasingController>().errorMessage ??
                'El backend no devolvió la orden solicitada.',
            actionLabel: 'Volver',
            onAction: () => context.go('/app/admin/purchasing/orders'),
          );
        }
        return _content(context, order);
      },
    );
  }

  Widget _content(BuildContext context, PurchaseOrder order) {
    final controller = context.watch<PurchasingController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: order.folio,
            subtitle: '${order.supplier} · ${order.branchName}',
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/app/admin/purchasing/orders'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Órdenes'),
              ),
              if (order.canEdit)
                OutlinedButton.icon(
                  onPressed: controller.saving
                      ? null
                      : () => _editNotes(context, order),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Editar notas'),
                ),
              if (order.canSubmit)
                FilledButton.icon(
                  onPressed: controller.saving
                      ? null
                      : () => _submit(context, order),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Enviar'),
                ),
              if (order.canReceive)
                FilledButton.icon(
                  onPressed: controller.saving
                      ? null
                      : () => _showReceiveDialog(context, order),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Recibir mercancía'),
                ),
              if (order.canCancel)
                OutlinedButton.icon(
                  onPressed: controller.saving
                      ? null
                      : () => _cancel(context, order),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar orden'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  PurchaseOrderStatusBadge(status: order.status),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      order.notes?.isNotEmpty == true
                          ? order.notes!
                          : 'Sin notas',
                    ),
                  ),
                  Text(
                    AppFormatters.currency(order.total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Producto')),
                  DataColumn(label: Text('Ordenado'), numeric: true),
                  DataColumn(label: Text('Recibido'), numeric: true),
                  DataColumn(label: Text('Pendiente'), numeric: true),
                  DataColumn(label: Text('Costo'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                ],
                rows: [
                  for (final line in order.items)
                    DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(line.productName),
                              subtitle: Text(line.sku),
                            ),
                          ),
                        ),
                        DataCell(Text('${line.quantityOrdered}')),
                        DataCell(Text('${line.quantityReceived}')),
                        DataCell(Text('${line.pending}')),
                        DataCell(Text(AppFormatters.currency(line.unitCost))),
                        DataCell(Text(AppFormatters.currency(line.lineTotal))),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (order.receipts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recepciones',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final receipt in order.receipts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                        title: Text(receipt.number),
                        subtitle: Text(
                          receipt.notes ??
                              AppFormatters.date(receipt.receivedAt),
                        ),
                        trailing: Text('${receipt.items.length} partidas'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editNotes(BuildContext context, PurchaseOrder order) async {
    final notes = TextEditingController(text: order.notes);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar notas'),
        content: TextField(
          controller: notes,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Notas'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, notes.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    notes.dispose();
    if (value == null || !context.mounted) return;
    final controller = context.read<PurchasingController>();
    final ok = await controller.updateOrder(order.id, {'notes': value});
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Notas actualizadas.');
    if (ok) _reload();
  }

  Future<void> _submit(BuildContext context, PurchaseOrder order) async {
    final controller = context.read<PurchasingController>();
    final ok = await controller.submitOrder(order.id);
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Orden enviada.');
    if (ok) _reload();
  }

  Future<void> _cancel(BuildContext context, PurchaseOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar orden'),
        content: const Text(
          'La cancelación solo es válida si la orden no tiene recepciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar orden'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final controller = context.read<PurchasingController>();
    final ok = await controller.cancelOrder(order.id);
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Orden cancelada.');
    if (ok) _reload();
  }

  Future<void> _showReceiveDialog(
    BuildContext context,
    PurchaseOrder order,
  ) async {
    final pending = order.items.where((item) => item.pending > 0).toList();
    final controllers = {
      for (final item in pending)
        item.id: TextEditingController(text: '${item.pending}'),
    };
    final notes = TextEditingController();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recepción de mercancía'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Confirma cantidades. El backend incrementará el stock al registrar la recepción.',
              ),
              const SizedBox(height: 14),
              for (final line in pending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[line.id],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: line.productName,
                      helperText: 'Pendiente: ${line.pending}',
                    ),
                  ),
                ),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notas'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final items = <Map<String, Object?>>[];
              for (final line in pending) {
                final value = int.tryParse(controllers[line.id]!.text) ?? 0;
                if (value > 0 && value <= line.pending) {
                  items.add({
                    'purchaseOrderItemId': line.id,
                    'quantityReceived': value,
                  });
                }
              }
              if (items.isEmpty) return;
              Navigator.pop(dialogContext, {
                if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
                'items': items,
              });
            },
            child: const Text('Confirmar recepción'),
          ),
        ],
      ),
    );
    notes.dispose();
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (payload == null || !context.mounted) return;
    final controller = context.read<PurchasingController>();
    final ok = await controller.receiveOrder(order.id, payload);
    if (!context.mounted) return;
    _feedback(
      context,
      ok,
      controller.errorMessage,
      'Recepción registrada; inventario actualizado.',
    );
    if (ok) {
      context.read<InventoryController>().load(force: true);
      _reload();
    }
  }

  static void _feedback(
    BuildContext context,
    bool ok,
    String? error,
    String success,
  ) {
    if (ok) {
      AppSuccessFeedback.show(context, success);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No fue posible completar la acción.')),
      );
    }
  }
}
