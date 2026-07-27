import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../../data/models/tenant_admin_models.dart';
import '../controllers/tenant_admin_controller.dart';

class TenantUsersPage extends StatefulWidget {
  const TenantUsersPage({super.key});

  @override
  State<TenantUsersPage> createState() => _TenantUsersPageState();
}

class _TenantUsersPageState extends State<TenantUsersPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<TenantAdminController>();
    if (controller.status == TenantAdminStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TenantAdminController>();
    if (controller.status == TenantAdminStatus.loading &&
        controller.employees.isEmpty) {
      return const AppLoadingState(message: 'Cargando empleados…');
    }
    if (controller.status == TenantAdminStatus.error) {
      return AppErrorState(
        message: controller.errorMessage ?? 'No fue posible cargar empleados.',
        onRetry: () => controller.load(force: true),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Empleados',
            subtitle: 'Usuarios y asignaciones devueltos por el backend.',
            actions: [
              FilledButton.icon(
                onPressed: controller.saving ? null : () => _showForm(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Nuevo empleado'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (controller.employees.isEmpty)
            const OperationalEmptyState(
              title: 'Sin empleados',
              message: 'Todavía no hay empleados administrables.',
            )
          else
            Card(
              child: Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Empleado')),
                      DataColumn(label: Text('Correo')),
                      DataColumn(label: Text('Rol')),
                      DataColumn(label: Text('Sucursal')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows: [
                      for (final user in controller.employees)
                        DataRow(
                          cells: [
                            DataCell(Text(user.name)),
                            DataCell(Text(user.email)),
                            DataCell(
                              RoleBadge(role: user.roleCode ?? 'SIN ROL'),
                            ),
                            DataCell(
                              Text(user.branchName ?? 'Tenant completo'),
                            ),
                            DataCell(
                              AppBadge(
                                label: user.status,
                                color: user.active ? Colors.green : Colors.grey,
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: controller.saving
                                        ? null
                                        : () => _showForm(
                                            context,
                                            employee: user,
                                          ),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: user.active
                                        ? 'Desactivar'
                                        : 'Activar',
                                    onPressed: controller.saving
                                        ? null
                                        : () => _changeStatus(context, user),
                                    icon: Icon(
                                      user.active
                                          ? Icons.person_off_outlined
                                          : Icons.person_add_alt,
                                    ),
                                  ),
                                ],
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

  Future<void> _changeStatus(
    BuildContext context,
    TenantEmployee employee,
  ) async {
    final controller = context.read<TenantAdminController>();
    final ok = await controller.changeEmployeeStatus(
      employee.id,
      employee.active ? 'INACTIVE' : 'ACTIVE',
    );
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage, 'Estado actualizado.');
  }

  Future<void> _showForm(
    BuildContext context, {
    TenantEmployee? employee,
  }) async {
    final admin = context.read<TenantAdminController>();
    final session = context.read<TenantSessionController>();
    final allowedRoles = admin.roles
        .where(
          (role) =>
              role.code != 'OWNER' &&
              (session.isOwner ||
                  role.code == 'CASHIER' ||
                  role.code == 'WAITER'),
        )
        .toList(growable: false);
    if (allowedRoles.isEmpty) {
      _feedback(context, false, 'No hay roles asignables disponibles.', '');
      return;
    }
    final name = TextEditingController(text: employee?.name);
    final email = TextEditingController(text: employee?.email);
    final password = TextEditingController();
    String roleCode = allowedRoles.any((r) => r.code == employee?.roleCode)
        ? employee!.roleCode!
        : allowedRoles.first.code;
    String? branchId = employee?.branchId ?? session.activeBranchId;
    final formKey = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final requiresBranch = roleCode == 'CASHIER' || roleCode == 'WAITER';
          return AlertDialog(
            title: Text(
              employee == null ? 'Nuevo empleado' : 'Editar empleado',
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: formKey,
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
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo'),
                        validator: (value) => value?.contains('@') == true
                            ? null
                            : 'Correo inválido.',
                      ),
                      if (employee == null) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña inicial',
                          ),
                          validator: (value) =>
                              value != null && value.length >= 8
                              ? null
                              : 'Usa al menos 8 caracteres.',
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: roleCode,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: [
                          for (final role in allowedRoles)
                            DropdownMenuItem(
                              value: role.code,
                              child: Text(role.name),
                            ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => roleCode = value ?? roleCode),
                      ),
                      if (requiresBranch) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue:
                              admin.branches.any(
                                (branch) => branch.id == branchId,
                              )
                              ? branchId
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Sucursal',
                          ),
                          items: [
                            for (final branch in admin.branches.where(
                              (branch) => branch.isActive,
                            ))
                              DropdownMenuItem(
                                value: branch.id,
                                child: Text(branch.name),
                              ),
                          ],
                          validator: (value) =>
                              value == null ? 'Selecciona una sucursal.' : null,
                          onChanged: (value) =>
                              setDialogState(() => branchId = value),
                        ),
                      ],
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
                  Navigator.pop(dialogContext, {
                    'fullName': name.text.trim(),
                    'email': email.text.trim(),
                    if (employee == null) 'password': password.text,
                    'roleCode': roleCode,
                    'branchId': requiresBranch ? branchId : null,
                  });
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    name.dispose();
    email.dispose();
    password.dispose();
    if (payload == null || !context.mounted) return;
    final ok = employee == null
        ? await admin.createEmployee(payload)
        : await admin.updateEmployee(employee.id, payload);
    if (!context.mounted) return;
    _feedback(context, ok, admin.errorMessage, 'Empleado guardado.');
  }

  static String? _required(String? value) =>
      value == null || value.trim().length < 2
      ? 'Ingresa al menos 2 caracteres.'
      : null;

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
