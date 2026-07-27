import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
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
    if (controller.status == TenantAdminStatus.loading) {
      return const AppLoadingState(message: 'Cargando roles…');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Roles y permisos',
            subtitle: 'Capacidades disponibles por perfil operativo.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 700 ? 1 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: constraints.maxWidth < 700 ? 1.8 : 1.55,
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
                            Text(
                              '${role.users} usuarios',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Text(
                          role.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          role.description,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const Spacer(),
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
}
