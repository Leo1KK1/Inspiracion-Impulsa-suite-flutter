import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../../data/models/inventory_models.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/stock_status_badge.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<InventoryController>();
    if (controller.status == InventoryStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    final isOwner = context.watch<TenantSessionController>().isOwner;
    if (inventory.status == InventoryStatus.loading &&
        inventory.products.isEmpty) {
      return const AppLoadingState(message: 'Cargando productos…');
    }
    if (inventory.status == InventoryStatus.error) {
      return AppErrorState(
        message: inventory.errorMessage ?? 'No fue posible cargar productos.',
        onRetry: () => inventory.load(force: true),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Catálogo de productos',
            subtitle: 'Catálogo global y stock de la sucursal activa.',
            actions: [
              if (isOwner)
                FilledButton.icon(
                  onPressed: inventory.saving
                      ? null
                      : () => _showProductForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo producto'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  onChanged: inventory.setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, SKU o código…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String?>(
                  initialValue: inventory.categoryId,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final category in inventory.categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: inventory.setCategory,
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String?>(
                  initialValue: inventory.statusFilter,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'ACTIVE', child: Text('Activo')),
                    DropdownMenuItem(
                      value: 'INACTIVE',
                      child: Text('Inactivo'),
                    ),
                  ],
                  onChanged: inventory.setStatusFilter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (inventory.filteredProducts.isEmpty)
            const OperationalEmptyState(
              title: 'Sin productos',
              message: 'No hay productos que coincidan con los filtros.',
            )
          else
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Categoría')),
                    DataColumn(label: Text('Precio'), numeric: true),
                    DataColumn(label: Text('Disponible'), numeric: true),
                    DataColumn(label: Text('Nivel')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final product in inventory.filteredProducts)
                      _row(context, inventory, product),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _row(
    BuildContext context,
    InventoryController inventory,
    Product product,
  ) {
    final stock = inventory.stockFor(product.id);
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 250,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.inventory_2_outlined),
              ),
              title: Text(product.name),
              subtitle: Text(product.sku),
            ),
          ),
        ),
        DataCell(Text(product.categoryName)),
        DataCell(Text(AppFormatters.currency(product.price))),
        DataCell(Text(stock == null ? 'Sin alta' : '${stock.availableStock}')),
        DataCell(
          stock == null
              ? const AppBadge(
                  label: 'SIN INVENTARIO',
                  color: AppColors.mutedForeground,
                )
              : StockStatusBadge(
                  stock: stock.stockOnHand,
                  minimum: stock.minStock,
                ),
        ),
        DataCell(
          AppBadge(
            label: product.status.name.toUpperCase(),
            color: product.isActive
                ? AppColors.success
                : AppColors.mutedForeground,
          ),
        ),
        DataCell(
          IconButton(
            tooltip: 'Ver detalle',
            onPressed: () =>
                context.go('/app/admin/inventory/products/${product.id}'),
            icon: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }

  Future<void> _showProductForm(BuildContext context) async {
    final inventory = context.read<InventoryController>();
    if (inventory.categories.isEmpty) {
      _error(context, 'Primero crea una categoría.');
      return;
    }
    final key = GlobalKey<FormState>();
    final sku = TextEditingController();
    final barcode = TextEditingController();
    final name = TextEditingController();
    final description = TextEditingController();
    final cost = TextEditingController(text: '0');
    final price = TextEditingController();
    final unit = TextEditingController(text: 'pieza');
    final initialStock = TextEditingController(text: '0');
    final minimum = TextEditingController(text: '0');
    final imageUrl = TextEditingController();
    var categoryId = inventory.categories.first.id;
    final payload = await showDialog<_ProductDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo producto'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 650),
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
                        Expanded(
                          child: TextFormField(
                            controller: sku,
                            decoration: const InputDecoration(labelText: 'SKU'),
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: barcode,
                            decoration: const InputDecoration(
                              labelText: 'Código de barras',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        for (final category in inventory.categories.where(
                          (category) => category.isActive,
                        ))
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) => setDialogState(
                        () => categoryId = value ?? categoryId,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _NumberField('Costo', cost)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NumberField(
                            'Precio',
                            price,
                            mustBePositive: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: unit,
                            decoration: const InputDecoration(
                              labelText: 'Unidad',
                            ),
                            validator: _required,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            'Stock inicial',
                            initialStock,
                            integer: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NumberField(
                            'Stock mínimo',
                            minimum,
                            integer: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageUrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL de imagen (opcional)',
                        helperText:
                            'Puede ser URL absoluta o una ruta válida para el storage.',
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
                final url = imageUrl.text.trim();
                Navigator.pop(
                  dialogContext,
                  _ProductDraft(
                    payload: {
                      'name': name.text.trim(),
                      'sku': sku.text.trim().toUpperCase(),
                      if (barcode.text.trim().isNotEmpty)
                        'barcode': barcode.text.trim(),
                      'categoryId': categoryId,
                      'costPrice': double.parse(cost.text),
                      'salePrice': double.parse(price.text),
                      if (description.text.trim().isNotEmpty)
                        'description': description.text.trim(),
                      'unitName': unit.text.trim(),
                      if (url.isNotEmpty)
                        'images': [
                          {
                            'url': url,
                            'altText': name.text.trim(),
                            'sortOrder': 0,
                            'isPrimary': true,
                          },
                        ],
                    },
                    sku: sku.text.trim().toUpperCase(),
                    initialStock: int.parse(initialStock.text),
                    minStock: int.parse(minimum.text),
                  ),
                );
              },
              child: const Text('Crear producto'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      sku,
      barcode,
      name,
      description,
      cost,
      price,
      unit,
      initialStock,
      minimum,
      imageUrl,
    ]) {
      controller.dispose();
    }
    if (payload == null || !context.mounted) return;
    final created = await inventory.createProduct(payload.payload);
    if (!context.mounted) return;
    if (!created) {
      _error(context, inventory.errorMessage);
      return;
    }
    final product = inventory.products
        .where((item) => item.sku == payload.sku)
        .firstOrNull;
    var inventoryConfigured = true;
    if (product != null && payload.initialStock > 0) {
      inventoryConfigured = await inventory.adjustStock({
        'productId': product.id,
        'quantityDelta': payload.initialStock,
        'movementType': 'MANUAL_ADJUSTMENT',
        'notes': 'Carga inicial desde alta de producto',
      });
    }
    if (product != null && payload.minStock > 0) {
      inventoryConfigured =
          await inventory.updateMinStock({
            'productId': product.id,
            'minStock': payload.minStock,
          }) &&
          inventoryConfigured;
    }
    if (!context.mounted) return;
    if (inventoryConfigured) {
      AppSuccessFeedback.show(context, 'Producto creado en el backend.');
    } else {
      _error(
        context,
        'El producto se creó, pero no se completó su configuración de stock: ${inventory.errorMessage ?? 'revisa el inventario.'}',
      );
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().length < 2
      ? 'Ingresa al menos 2 caracteres.'
      : null;

  static void _error(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'No fue posible guardar el producto.')),
    );
  }
}

class _ProductDraft {
  const _ProductDraft({
    required this.payload,
    required this.sku,
    required this.initialStock,
    required this.minStock,
  });

  final Map<String, Object?> payload;
  final String sku;
  final int initialStock;
  final int minStock;
}

class _NumberField extends StatelessWidget {
  const _NumberField(
    this.label,
    this.controller, {
    this.integer = false,
    this.mustBePositive = false,
  });

  final String label;
  final TextEditingController controller;
  final bool integer;
  final bool mustBePositive;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = num.tryParse(value ?? '');
      if (number == null || number < 0) return 'Valor inválido.';
      if (mustBePositive && number <= 0) return 'Debe ser mayor a cero.';
      if (integer && number % 1 != 0) return 'Usa un entero.';
      return null;
    },
  );
}
