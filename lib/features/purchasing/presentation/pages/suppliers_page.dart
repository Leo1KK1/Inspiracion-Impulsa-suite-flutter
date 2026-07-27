import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/purchasing_models.dart';
import '../controllers/purchasing_controller.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    final controller = context.read<PurchasingController>();
    if (controller.status == PurchasingStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PurchasingController>();
    if (controller.status == PurchasingStatus.loading &&
        controller.suppliers.isEmpty) {
      return const AppLoadingState(message: 'Cargando proveedores…');
    }
    if (controller.status == PurchasingStatus.error) {
      return AppErrorState(
        message:
            controller.errorMessage ?? 'No fue posible cargar proveedores.',
        onRetry: () => controller.load(force: true),
      );
    }
    final query = _query.trim().toLowerCase();
    final suppliers = controller.suppliers
        .where(
          (supplier) =>
              query.isEmpty ||
              supplier.name.toLowerCase().contains(query) ||
              supplier.taxId?.toLowerCase().contains(query) == true,
        )
        .toList(growable: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Proveedores',
            subtitle: 'Directorio global de compras del tenant.',
            actions: [
              FilledButton.icon(
                onPressed: controller.saving
                    ? null
                    : () => _showSupplierForm(context),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Nuevo proveedor'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o RFC…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (suppliers.isEmpty)
            const OperationalEmptyState(
              title: 'Sin proveedores',
              message: 'No hay proveedores que coincidan con la búsqueda.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth < 720 ? 1 : 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.8,
                ),
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.local_shipping_outlined),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  supplier.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              AppBadge(
                                label: supplier.active ? 'ACTIVO' : 'INACTIVO',
                                color: supplier.active
                                    ? AppColors.success
                                    : AppColors.mutedForeground,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('RFC: ${supplier.taxId ?? 'No registrado'}'),
                          Text(
                            supplier.contactName ?? 'Sin contacto registrado',
                          ),
                          Text(supplier.contactEmail ?? ''),
                          Text(supplier.contactPhone ?? ''),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: controller.saving
                                    ? null
                                    : () => _showSupplierForm(
                                        context,
                                        supplier: supplier,
                                      ),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: supplier.active
                                    ? 'Desactivar'
                                    : 'Activar',
                                onPressed: controller.saving
                                    ? null
                                    : () => _toggle(context, supplier),
                                icon: Icon(
                                  supplier.active
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggle(BuildContext context, Supplier supplier) async {
    final controller = context.read<PurchasingController>();
    final ok = await controller.updateSupplier(supplier.id, {
      'isActive': !supplier.active,
    });
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage);
  }

  Future<void> _showSupplierForm(
    BuildContext context, {
    Supplier? supplier,
  }) async {
    final name = TextEditingController(text: supplier?.name);
    final taxId = TextEditingController(text: supplier?.taxId);
    final contact = TextEditingController(text: supplier?.contactName);
    final email = TextEditingController(text: supplier?.contactEmail);
    final phone = TextEditingController(text: supplier?.contactPhone);
    final address = TextEditingController(text: supplier?.address);
    final key = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(supplier == null ? 'Nuevo proveedor' : 'Editar proveedor'),
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
                  TextFormField(
                    controller: taxId,
                    decoration: const InputDecoration(
                      labelText: 'RFC / Tax ID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contact,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de contacto',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (value) =>
                        value?.isNotEmpty == true && !value!.contains('@')
                        ? 'Correo inválido.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Dirección'),
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
                'name': name.text.trim(),
                if (taxId.text.trim().isNotEmpty) 'taxId': taxId.text.trim(),
                if (contact.text.trim().isNotEmpty)
                  'contactName': contact.text.trim(),
                if (email.text.trim().isNotEmpty)
                  'contactEmail': email.text.trim(),
                if (phone.text.trim().isNotEmpty)
                  'contactPhone': phone.text.trim(),
                if (address.text.trim().isNotEmpty)
                  'address': address.text.trim(),
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    for (final item in [name, taxId, contact, email, phone, address]) {
      item.dispose();
    }
    if (payload == null || !context.mounted) return;
    final controller = context.read<PurchasingController>();
    final ok = supplier == null
        ? await controller.createSupplier(payload)
        : await controller.updateSupplier(supplier.id, payload);
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage);
  }

  static String? _required(String? value) =>
      value == null || value.trim().length < 2
      ? 'Ingresa al menos 2 caracteres.'
      : null;

  static void _feedback(BuildContext context, bool ok, String? error) {
    if (ok) {
      AppSuccessFeedback.show(context, 'Proveedor guardado en el backend.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No fue posible guardar el proveedor.'),
        ),
      );
    }
  }
}
