import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
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
    final isOwner = context.watch<TenantSessionController>().isOwner;
    if (controller.status == TenantAdminStatus.loading &&
        controller.branches.isEmpty) {
      return const AppLoadingState(message: 'Cargando sucursales…');
    }
    if (controller.status == TenantAdminStatus.error) {
      return AppErrorState(
        message: controller.errorMessage ?? 'No fue posible cargar sucursales.',
        onRetry: () => controller.load(force: true),
      );
    }
    final query = _search.trim().toLowerCase();
    final branches = controller.branches
        .where(
          (branch) =>
              branch.name.toLowerCase().contains(query) ||
              branch.code.toLowerCase().contains(query),
        )
        .toList(growable: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Sucursales',
            subtitle: 'Sedes y estado operativo registrados en el backend.',
            actions: [
              if (isOwner)
                FilledButton.icon(
                  onPressed: controller.saving
                      ? null
                      : () => _showBranchForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva sucursal'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o código…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (branches.isEmpty)
            const OperationalEmptyState(
              title: 'Sin sucursales',
              message: 'No hay sucursales que coincidan con el criterio.',
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
                  childAspectRatio: 1.35,
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
                                color: branch.isActive
                                    ? AppColors.success
                                    : AppColors.mutedForeground,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            branch.code,
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            branch.address?.trim().isNotEmpty == true
                                ? branch.address!
                                : 'Sin dirección registrada',
                          ),
                          const Spacer(),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${branch.employeeCount} empleados',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isOwner) ...[
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: controller.saving
                                      ? null
                                      : () => _showBranchForm(
                                          context,
                                          branch: branch,
                                        ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: branch.isActive
                                      ? 'Desactivar'
                                      : 'Activar',
                                  onPressed: controller.saving
                                      ? null
                                      : () => _changeStatus(context, branch),
                                  icon: Icon(
                                    branch.isActive
                                        ? Icons.pause_circle_outline
                                        : Icons.play_circle_outline,
                                  ),
                                ),
                              ],
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

  Future<void> _changeStatus(BuildContext context, Branch branch) async {
    final next = branch.isActive ? 'INACTIVE' : 'ACTIVE';
    final controller = context.read<TenantAdminController>();
    final ok = await controller.changeBranchStatus(branch.id, next);
    if (!context.mounted) return;
    if (ok) {
      AppSuccessFeedback.show(context, 'Estado de sucursal actualizado.');
    } else {
      _showError(context, controller.errorMessage);
    }
  }

  Future<void> _showBranchForm(BuildContext context, {Branch? branch}) async {
    final name = TextEditingController(text: branch?.name);
    final code = TextEditingController(text: branch?.code);
    final address = TextEditingController(text: branch?.address);
    final key = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(branch == null ? 'Nueva sucursal' : 'Editar sucursal'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: key,
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
                  controller: code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Código'),
                  validator: _required,
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
                'code': code.text.trim().toUpperCase(),
                if (address.text.trim().isNotEmpty)
                  'address': address.text.trim(),
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    name.dispose();
    code.dispose();
    address.dispose();
    if (payload == null || !context.mounted) return;
    final controller = context.read<TenantAdminController>();
    final ok = branch == null
        ? await controller.createBranch(payload)
        : await controller.updateBranch(branch.id, payload);
    if (!context.mounted) return;
    if (ok) {
      AppSuccessFeedback.show(context, 'Sucursal guardada correctamente.');
    } else {
      _showError(context, controller.errorMessage);
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().length < 2
      ? 'Ingresa al menos 2 caracteres.'
      : null;

  static void _showError(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'No fue posible guardar los cambios.')),
    );
  }
}
