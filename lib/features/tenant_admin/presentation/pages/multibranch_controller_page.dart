import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../controllers/tenant_admin_controller.dart';

class MultibranchControllerPage extends StatefulWidget {
  const MultibranchControllerPage({super.key});

  @override
  State<MultibranchControllerPage> createState() =>
      _MultibranchControllerPageState();
}

class _MultibranchControllerPageState extends State<MultibranchControllerPage> {
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
        controller.branchStaff.isEmpty) {
      return const AppLoadingState(message: 'Cargando acceso multisucursal…');
    }
    if (controller.status == TenantAdminStatus.error) {
      return AppErrorState(
        message: controller.errorMessage ?? 'No fue posible cargar accesos.',
        onRetry: () => controller.load(force: true),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Control multisucursal',
            subtitle:
                'Consulta de responsables y empleados asignados por sucursal.',
          ),
          const SizedBox(height: 12),
          const Text(
            'La API actual no ofrece una mutación masiva de asignaciones; esta vista refleja únicamente los datos persistidos.',
            style: TextStyle(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 18),
          if (controller.branchStaff.isEmpty)
            const OperationalEmptyState(
              title: 'Sin asignaciones',
              message: 'No hay información multisucursal disponible.',
            )
          else
            for (final group in controller.branchStaff)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.store_mall_directory_outlined),
                    title: Text(group.branch.name),
                    subtitle: Text(
                      '${group.branch.code} · ${group.employees.length} empleados',
                    ),
                    trailing: AppBadge(
                      label: group.branch.status,
                      color: group.branch.isActive
                          ? AppColors.success
                          : AppColors.mutedForeground,
                    ),
                    children: [
                      if (group.managers.isNotEmpty) ...[
                        const ListTile(
                          title: Text(
                            'Acceso de tenant',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        for (final person in group.managers)
                          ListTile(
                            leading: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            title: Text(person.name),
                            subtitle: Text(person.email),
                            trailing: RoleBadge(
                              role: person.roleCode ?? 'SIN ROL',
                            ),
                          ),
                      ],
                      const ListTile(
                        title: Text(
                          'Personal asignado',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (group.employees.isEmpty)
                        const ListTile(title: Text('Sin personal asignado'))
                      else
                        for (final person in group.employees)
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(person.name),
                            subtitle: Text(person.email),
                            trailing: RoleBadge(
                              role: person.roleCode ?? 'SIN ROL',
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
}
