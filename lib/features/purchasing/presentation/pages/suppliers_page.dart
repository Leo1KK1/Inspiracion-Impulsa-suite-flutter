import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
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
    if (controller.status == PurchasingStatus.loading) {
      return const AppLoadingState(message: 'Cargando proveedores…');
    }
    final suppliers = controller.suppliers
        .where(
          (supplier) =>
              supplier.name.toLowerCase().contains(_query.toLowerCase()) ||
              supplier.code.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Proveedores',
            subtitle: 'Directorio y condiciones comerciales.',
            actions: [
              FilledButton.icon(
                onPressed: () => _showSupplierForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo proveedor'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Buscar proveedor…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 760 ? 1 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth < 760 ? 1.8 : 1.65,
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
                              child: Icon(Icons.business_outlined),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplier.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${supplier.code} · ${supplier.rfc}',
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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
                        const SizedBox(height: 14),
                        Text('${supplier.contact} · ${supplier.phone}'),
                        Text(
                          supplier.email,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final category in supplier.categories)
                              AppBadge(
                                label: category,
                                color: AppColors.tenantAccent,
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          '${supplier.totalOrders} órdenes · ${supplier.paymentTerms}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
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

  Future<void> _showSupplierForm(BuildContext context) async {
    final name = TextEditingController();
    final rfc = TextEditingController();
    final email = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo proveedor'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Razón social'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rfc,
                decoration: const InputDecoration(labelText: 'RFC'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Correo'),
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
              if (name.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              AppSuccessFeedback.show(context, 'Proveedor guardado en mock.');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    name.dispose();
    rfc.dispose();
    email.dispose();
  }
}
