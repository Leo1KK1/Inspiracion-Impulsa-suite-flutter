import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
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
    if (inventory.status == InventoryStatus.loading) {
      return const AppLoadingState(message: 'Cargando productos…');
    }
    if (inventory.status == InventoryStatus.error) {
      return AppErrorState(
        message: inventory.errorMessage!,
        onRetry: inventory.load,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Catálogo de productos',
            subtitle: 'Productos, precios y existencias por sucursal.',
            actions: [
              FilledButton.icon(
                onPressed: () => _showProductForm(context),
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
                width: 340,
                child: TextField(
                  onChanged: inventory.setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o SKU…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  initialValue: inventory.category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [
                    const DropdownMenuItem(
                      value: 'Todas',
                      child: Text('Todas'),
                    ),
                    for (final category in inventory.categories)
                      DropdownMenuItem(
                        value: category.name,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) => inventory.setCategory(value ?? 'Todas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (inventory.filteredProducts.isEmpty)
            OperationalEmptyState(
              title: 'Sin productos',
              message: 'Ajusta los filtros o crea un producto nuevo.',
              actionLabel: 'Limpiar filtros',
              onAction: () {
                inventory
                  ..setQuery('')
                  ..setCategory('Todas');
              },
            )
          else
            Card(
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Producto')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Precio'), numeric: true),
                      DataColumn(label: Text('Stock'), numeric: true),
                      DataColumn(label: Text('Nivel')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final product in inventory.filteredProducts)
                        DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 240,
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
                            DataCell(Text(product.category)),
                            DataCell(
                              Text(AppFormatters.currency(product.price)),
                            ),
                            DataCell(Text('${product.stock} ${product.unit}')),
                            DataCell(
                              StockStatusBadge(
                                stock: product.stock,
                                minimum: product.minStock,
                              ),
                            ),
                            DataCell(
                              AppBadge(
                                label: product.status.name.toUpperCase(),
                                color: product.status == ProductStatus.active
                                    ? AppColors.success
                                    : AppColors.mutedForeground,
                              ),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Ver detalle',
                                onPressed: () => context.go(
                                  '/app/admin/inventory/products/${product.id}',
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
            ),
        ],
      ),
    );
  }

  Future<void> _showProductForm(BuildContext context) async {
    final key = GlobalKey<FormState>();
    final sku = TextEditingController();
    final name = TextEditingController();
    final cost = TextEditingController();
    final price = TextEditingController();
    final stock = TextEditingController();
    final minimum = TextEditingController();
    var category = 'Bebidas';
    String? fileName;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo producto'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660, maxHeight: 600),
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );
                        if (result != null) {
                          setDialogState(
                            () => fileName = result.files.single.name,
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_outlined),
                      label: Text(fileName ?? 'Subir foto (JPG o PNG)'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: sku,
                            decoration: const InputDecoration(
                              labelText: 'SKU / código',
                            ),
                            validator: _required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Bebidas',
                                child: Text('Bebidas'),
                              ),
                              DropdownMenuItem(
                                value: 'Alimentos',
                                child: Text('Alimentos'),
                              ),
                              DropdownMenuItem(
                                value: 'Desechables',
                                child: Text('Desechables'),
                              ),
                              DropdownMenuItem(
                                value: 'Limpieza',
                                child: Text('Limpieza'),
                              ),
                            ],
                            onChanged: (value) => category = value ?? category,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _NumberField('Costo', cost)),
                        const SizedBox(width: 12),
                        Expanded(child: _NumberField('Precio', price)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _NumberField('Stock inicial', stock)),
                        const SizedBox(width: 12),
                        Expanded(child: _NumberField('Stock mínimo', minimum)),
                      ],
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
                final inventory = context.read<InventoryController>();
                inventory.addProduct(
                  Product(
                    id: 'p${inventory.products.length + 1}',
                    sku: sku.text,
                    name: name.text,
                    category: category,
                    unit: 'pieza',
                    cost: double.parse(cost.text),
                    price: double.parse(price.text),
                    stock: int.parse(stock.text),
                    minStock: int.parse(minimum.text),
                    status: ProductStatus.active,
                  ),
                );
                Navigator.pop(dialogContext);
                AppSuccessFeedback.show(context, 'Producto creado.');
              },
              child: const Text('Crear producto'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [sku, name, cost, price, stock, minimum]) {
      controller.dispose();
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;
}

class _NumberField extends StatelessWidget {
  const _NumberField(this.label, this.controller);
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = num.tryParse(value ?? '');
      return number == null || number < 0 ? 'Valor inválido.' : null;
    },
  );
}
