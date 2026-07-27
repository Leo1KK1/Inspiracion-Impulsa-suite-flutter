import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
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
    if (controller.status == TenantAdminStatus.loading) {
      return const AppLoadingState(message: 'Cargando empleados…');
    }
    if (controller.status == TenantAdminStatus.error) {
      return AppErrorState(
        message: controller.errorMessage!,
        onRetry: controller.load,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Empleados',
            subtitle: 'Usuarios, roles y sucursales asignadas.',
            actions: [
              FilledButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Nuevo empleado'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Empleado')),
                    DataColumn(label: Text('Correo')),
                    DataColumn(label: Text('Rol')),
                    DataColumn(label: Text('Sucursales')),
                    DataColumn(label: Text('Estado')),
                  ],
                  rows: [
                    for (final user in controller.employees)
                      DataRow(
                        cells: [
                          DataCell(Text(user.name)),
                          DataCell(Text(user.email)),
                          DataCell(RoleBadge(role: user.role)),
                          DataCell(Text(user.branchIds.join(', '))),
                          DataCell(
                            AppBadge(
                              label: user.active ? 'ACTIVO' : 'INACTIVO',
                              color: user.active ? Colors.green : Colors.grey,
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

  Future<void> _showForm(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    var role = 'CASHIER';
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo empleado'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: formKey,
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
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: (value) => value?.contains('@') ?? false
                        ? null
                        : 'Correo inválido.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: const [
                      DropdownMenuItem(value: 'OWNER', child: Text('OWNER')),
                      DropdownMenuItem(
                        value: 'BRANCH_MANAGER',
                        child: Text('BRANCH_MANAGER'),
                      ),
                      DropdownMenuItem(
                        value: 'CASHIER',
                        child: Text('CASHIER'),
                      ),
                      DropdownMenuItem(value: 'WAITER', child: Text('WAITER')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => role = value ?? role),
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
                if (!formKey.currentState!.validate()) return;
                final controller = context.read<TenantAdminController>();
                controller.addEmployee(
                  TenantEmployee(
                    id: 'USR-${controller.employees.length + 140}',
                    name: name.text,
                    email: email.text,
                    role: role,
                    branchIds: const ['CDMX-01'],
                    active: true,
                  ),
                );
                Navigator.pop(dialogContext);
                AppSuccessFeedback.show(context, 'Empleado creado.');
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;
}
