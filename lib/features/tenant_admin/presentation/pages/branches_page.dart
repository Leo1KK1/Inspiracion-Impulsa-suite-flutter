import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/tenant_admin_models.dart';
import '../controllers/tenant_admin_controller.dart';

class BranchesPage extends StatefulWidget {
  const BranchesPage({super.key});

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    final controller = context.read<TenantAdminController>();
    if (controller.status == TenantAdminStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TenantAdminController>();
    if (controller.status == TenantAdminStatus.loading) {
      return const AppLoadingState(message: 'Cargando sucursales…');
    }
    if (controller.status == TenantAdminStatus.error) {
      return AppErrorState(
        message: controller.errorMessage!,
        onRetry: controller.load,
      );
    }
    final branches = controller.branches
        .where(
          (branch) =>
              branch.name.toLowerCase().contains(_search.toLowerCase()) ||
              branch.id.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Sucursales',
            subtitle: 'Administra sedes, responsables y estado operativo.',
            actions: [
              FilledButton.icon(
                onPressed: () => _showBranchForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Nueva sucursal'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o ID…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (branches.isEmpty)
            OperationalEmptyState(
              title: 'Sin resultados',
              message: 'No encontramos sucursales con ese criterio.',
              actionLabel: 'Limpiar búsqueda',
              onAction: () => setState(() => _search = ''),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth < 680
                      ? 1
                      : constraints.maxWidth < 1100
                      ? 2
                      : 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.45,
                ),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(
                                  Icons.store_mall_directory_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  branch.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              AppBadge(
                                label: branch.status,
                                color: branch.status == 'ACTIVA'
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            '${branch.id} · ${branch.city}',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          Text(branch.address),
                          const Spacer(),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: _SmallMetric(
                                  label: 'Ventas hoy',
                                  value: AppFormatters.currency(
                                    branch.salesToday,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _SmallMetric(
                                  label: 'Personal',
                                  value: '${branch.employees}',
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

  Future<void> _showBranchForm(BuildContext context) async {
    final name = TextEditingController();
    final city = TextEditingController();
    final address = TextEditingController();
    final key = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva sucursal'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: city,
                    decoration: const InputDecoration(labelText: 'Ciudad'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: address,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: _required,
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
              final controller = context.read<TenantAdminController>();
              controller.addBranch(
                Branch(
                  id: 'BR-${controller.branches.length + 1}',
                  name: name.text,
                  city: city.text,
                  address: address.text,
                  status: 'ACTIVA',
                  salesToday: 0,
                  employees: 0,
                ),
              );
              Navigator.pop(dialogContext);
              AppSuccessFeedback.show(
                context,
                'Sucursal creada correctamente.',
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    name.dispose();
    city.dispose();
    address.dispose();
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}
