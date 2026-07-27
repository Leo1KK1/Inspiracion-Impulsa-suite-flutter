import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../../data/models/inventory_models.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/stock_status_badge.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    final session = context.watch<TenantSessionController>();
    if (inventory.status == InventoryStatus.idle) {
      Future.microtask(inventory.load);
      return const AppLoadingState(message: 'Cargando producto…');
    }
    if (inventory.status == InventoryStatus.loading &&
        inventory.products.isEmpty) {
      return const AppLoadingState(message: 'Cargando producto…');
    }
    final product = inventory.products
        .where((item) => item.id == productId)
        .firstOrNull;
    if (product == null) {
      return OperationalEmptyState(
        title: 'Producto no encontrado',
        message: 'El backend no devolvió el producto solicitado.',
        actionLabel: 'Volver a productos',
        onAction: () => context.go('/app/admin/inventory/products'),
      );
    }
    final stock = inventory.stockFor(product.id);
    final movements = inventory.movementsFor(product.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: product.name,
            subtitle: '${product.sku} · ${product.categoryName}',
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/app/admin/inventory/products'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Productos'),
              ),
              if (session.isOwner)
                OutlinedButton.icon(
                  onPressed: inventory.saving
                      ? null
                      : () => _editProduct(context, product),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              if (session.isOwner)
                FilledButton.icon(
                  onPressed: inventory.saving
                      ? null
                      : () => _toggleProduct(context, product),
                  icon: Icon(
                    product.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  label: Text(product.isActive ? 'Desactivar' : 'Activar'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width < 800 ? 1 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.15,
            children: [
              MetricCard(
                label: 'Existencia',
                value: stock == null ? 'Sin alta' : '${stock.stockOnHand}',
                detail: stock == null
                    ? 'Registra una entrada'
                    : 'Disponible ${stock.availableStock}',
                icon: Icons.inventory_2_outlined,
              ),
              MetricCard(
                label: 'Reservado',
                value: '${stock?.reservedStock ?? 0}',
                icon: Icons.lock_clock_outlined,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Costo unitario',
                value: AppFormatters.currency(product.cost),
                icon: Icons.payments_outlined,
              ),
              MetricCard(
                label: 'Precio de venta',
                value: AppFormatters.currency(product.price),
                icon: Icons.sell_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Control de stock',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (stock != null)
                        StockStatusBadge(
                          stock: stock.stockOnHand,
                          minimum: stock.minStock,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: inventory.saving
                            ? null
                            : () => _adjustStock(context, product),
                        icon: const Icon(Icons.tune),
                        label: const Text('Registrar ajuste'),
                      ),
                      OutlinedButton.icon(
                        onPressed: inventory.saving
                            ? null
                            : () => _setMinimum(context, product, stock),
                        icon: const Icon(Icons.notification_important_outlined),
                        label: const Text('Stock mínimo'),
                      ),
                      if (stock != null)
                        OutlinedButton.icon(
                          onPressed: inventory.saving
                              ? null
                              : () => _reserve(context, product, stock),
                          icon: const Icon(Icons.inventory_outlined),
                          label: const Text('Reservar / liberar'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (product.images.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Imágenes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final image in product.images)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          image.isPrimary ? Icons.star : Icons.image_outlined,
                        ),
                        title: Text(image.altText ?? 'Imagen del producto'),
                        subtitle: Text(
                          image.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: session.isOwner
                            ? IconButton(
                                tooltip: 'Eliminar imagen',
                                onPressed: inventory.saving
                                    ? null
                                    : () =>
                                          _deleteImage(context, product, image),
                                icon: const Icon(Icons.delete_outline),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Movimientos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (movements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('No hay movimientos para este producto.'),
                    )
                  else
                    for (final movement in movements)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(movement.type),
                        subtitle: Text(
                          movement.notes ??
                              AppFormatters.date(movement.createdAt),
                        ),
                        trailing: Text(
                          '${movement.quantityDelta > 0 ? '+' : ''}${movement.quantityDelta} · ${movement.stockBefore} → ${movement.stockAfter}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProduct(BuildContext context, Product product) async {
    final name = TextEditingController(text: product.name);
    final cost = TextEditingController(text: '${product.cost}');
    final price = TextEditingController(text: '${product.price}');
    final description = TextEditingController(text: product.description);
    final unit = TextEditingController(text: product.unit);
    final imageUrl = TextEditingController();
    final key = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar producto'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _numberField('Costo', cost)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField('Precio', price, positive: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unit,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: imageUrl,
                    decoration: const InputDecoration(
                      labelText: 'Agregar imagen por URL (opcional)',
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
              final images = [
                for (final image in product.images) image.toPreserveJson(),
                if (imageUrl.text.trim().isNotEmpty)
                  {
                    'url': imageUrl.text.trim(),
                    'altText': name.text.trim(),
                    'sortOrder': product.images.length,
                    'isPrimary': product.images.isEmpty,
                  },
              ];
              Navigator.pop(dialogContext, {
                'name': name.text.trim(),
                'costPrice': double.parse(cost.text),
                'salePrice': double.parse(price.text),
                'unitName': unit.text.trim(),
                'description': description.text.trim(),
                if (imageUrl.text.trim().isNotEmpty) 'images': images,
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    for (final item in [name, cost, price, description, unit, imageUrl]) {
      item.dispose();
    }
    if (payload == null || !context.mounted) return;
    final controller = context.read<InventoryController>();
    final ok = await controller.updateProduct(product.id, payload);
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Producto actualizado.');
  }

  Future<void> _toggleProduct(BuildContext context, Product product) async {
    final controller = context.read<InventoryController>();
    final ok = await controller.changeProductStatus(
      product.id,
      product.isActive ? 'INACTIVE' : 'ACTIVE',
    );
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Estado actualizado.');
  }

  Future<void> _adjustStock(BuildContext context, Product product) async {
    final quantity = TextEditingController();
    final notes = TextEditingController();
    var type = 'MANUAL_ADJUSTMENT';
    final key = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar ajuste'),
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad (+ entrada / - salida)',
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    return parsed == null || parsed == 0
                        ? 'Ingresa un entero distinto de cero.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'MANUAL_ADJUSTMENT',
                      child: Text('Ajuste manual'),
                    ),
                    DropdownMenuItem(
                      value: 'STOCK_DECREASE',
                      child: Text('Salida de stock'),
                    ),
                    DropdownMenuItem(value: 'WASTE', child: Text('Merma')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? type),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Motivo'),
                  validator: _required,
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
                if (!key.currentState!.validate()) return;
                Navigator.pop(dialogContext, {
                  'productId': product.id,
                  'quantityDelta': int.parse(quantity.text),
                  'movementType': type,
                  'notes': notes.text.trim(),
                });
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    quantity.dispose();
    notes.dispose();
    if (payload == null || !context.mounted) return;
    final controller = context.read<InventoryController>();
    final ok = await controller.adjustStock(payload);
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Ajuste registrado.');
  }

  Future<void> _setMinimum(
    BuildContext context,
    Product product,
    InventoryItem? stock,
  ) async {
    final value = TextEditingController(text: '${stock?.minStock ?? 0}');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stock mínimo'),
        content: TextField(
          controller: value,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Unidades'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(value.text);
              if (parsed != null && parsed >= 0) {
                Navigator.pop(dialogContext, parsed);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    value.dispose();
    if (result == null || !context.mounted) return;
    final controller = context.read<InventoryController>();
    final ok = await controller.updateMinStock({
      'productId': product.id,
      'minStock': result,
    });
    if (!context.mounted) return;
    _feedback(
      context,
      ok,
      controller.errorMessage,
      'Stock mínimo actualizado.',
    );
  }

  Future<void> _reserve(
    BuildContext context,
    Product product,
    InventoryItem stock,
  ) async {
    final quantity = TextEditingController();
    final notes = TextEditingController();
    var action = 'RESERVE';
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reserva de stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: action,
                items: const [
                  DropdownMenuItem(value: 'RESERVE', child: Text('Reservar')),
                  DropdownMenuItem(value: 'RELEASE', child: Text('Liberar')),
                ],
                onChanged: (value) =>
                    setDialogState(() => action = value ?? action),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  helperText:
                      'Disponible ${stock.availableStock} · reservado ${stock.reservedStock}',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Motivo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(quantity.text);
                if (parsed == null ||
                    parsed <= 0 ||
                    notes.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, {
                  'productId': product.id,
                  'quantity': parsed,
                  'action': action,
                  'notes': notes.text.trim(),
                });
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    quantity.dispose();
    notes.dispose();
    if (payload == null || !context.mounted) return;
    final controller = context.read<InventoryController>();
    final ok = await controller.reserveStock(payload);
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Reserva actualizada.');
  }

  Future<void> _deleteImage(
    BuildContext context,
    Product product,
    ProductImage image,
  ) async {
    final controller = context.read<InventoryController>();
    final ok = await controller.deleteProductImage(product.id, image.id);
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Imagen eliminada.');
  }

  static Widget _numberField(
    String label,
    TextEditingController controller, {
    bool positive = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = num.tryParse(value ?? '');
      if (number == null || number < 0 || (positive && number <= 0)) {
        return 'Valor inválido.';
      }
      return null;
    },
  );

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;

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
        SnackBar(content: Text(error ?? 'No fue posible guardar los cambios.')),
      );
    }
  }
}
