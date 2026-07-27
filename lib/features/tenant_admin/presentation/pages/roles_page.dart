import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../controllers/tenant_admin_controller.dart';

class TenantRolesPage extends StatefulWidget {
  const TenantRolesPage({super.key});

  @override
  State<TenantRolesPage> createState() => _TenantRolesPageState();
}

class _TenantRolesPageState extends State<TenantRolesPage> {
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
        controller.roles.isEmpty) {
      return const AppLoadingState(message: 'Cargando roles…');
    }
    if (controller.status == TenantAdminStatus.error) {
      return AppErrorState(
        message: controller.errorMessage ?? 'No fue posible cargar roles.',
        onRetry: () => controller.load(force: true),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Roles y permisos',
            subtitle: 'Capacidades que el backend expone para este usuario.',
            actions: [
              if (isOwner)
                FilledButton.icon(
                  onPressed: controller.saving
                      ? null
                      : () => _showRoleForm(context),
                  icon: const Icon(Icons.add_moderator_outlined),
                  label: const Text('Nuevo rol'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (controller.roles.isEmpty)
            const OperationalEmptyState(
              title: 'Sin roles',
              message: 'No hay roles visibles para la sesión actual.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth < 700 ? 1 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth < 700 ? 1.7 : 1.45,
                ),
                itemCount: controller.roles.length,
                itemBuilder: (context, index) {
                  final role = controller.roles[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              RoleBadge(role: role.code),
                              const Spacer(),
                              if (role.scope case final scope?)
                                AppBadge(
                                  label: scope,
                                  color: AppColors.tenantAccent,
                                ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Text(
                            role.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (role.description.isNotEmpty)
                            Text(
                              role.description,
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          const Spacer(),
                          if (role.permissions.isEmpty)
                            const Text(
                              'Sin permisos vinculados',
                              style: TextStyle(
                                color: AppColors.mutedForeground,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                for (final permission in role.permissions)
                                  AppBadge(
                                    label: permission,
                                    color: AppColors.tenantAccent,
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

  Future<void> _showRoleForm(BuildContext context) async {
    final controller = context.read<TenantAdminController>();
    final availablePermissions =
        controller.roles.expand((role) => role.permissions).toSet().toList()
          ..sort();
    final code = TextEditingController();
    final name = TextEditingController();
    final description = TextEditingController();
    final selected = <String>{};
    var scope = 'BRANCH';
    final key = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo rol'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Código'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: scope,
                      decoration: const InputDecoration(labelText: 'Alcance'),
                      items: const [
                        DropdownMenuItem(
                          value: 'BRANCH',
                          child: Text('Sucursal'),
                        ),
                        DropdownMenuItem(
                          value: 'TENANT',
                          child: Text('Tenant'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => scope = value ?? scope),
                    ),
                    const SizedBox(height: 12),
                    if (availablePermissions.isEmpty)
                      const Text(
                        'El backend no devolvió permisos disponibles para vincular.',
                      )
                    else
                      for (final permission in availablePermissions)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: selected.contains(permission),
                          title: Text(permission),
                          onChanged: (checked) => setDialogState(() {
                            checked == true
                                ? selected.add(permission)
                                : selected.remove(permission);
                          }),
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
              onPressed: availablePermissions.isEmpty
                  ? null
                  : () {
                      if (!key.currentState!.validate()) return;
                      Navigator.pop(dialogContext, {
                        'code': code.text.trim().toUpperCase(),
                        'name': name.text.trim(),
                        if (description.text.trim().isNotEmpty)
                          'description': description.text.trim(),
                        'scope': scope,
                        'permissionCodes': selected.toList(),
                      });
                    },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    code.dispose();
    name.dispose();
    description.dispose();
    if (payload == null || !context.mounted) return;
    final ok = await controller.createRole(payload);
    if (!context.mounted) return;
    if (ok) {
      AppSuccessFeedback.show(context, 'Rol creado en el backend.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'No fue posible crear el rol.'),
        ),
      );
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().length < 2
      ? 'Ingresa al menos 2 caracteres.'
      : null;
}
