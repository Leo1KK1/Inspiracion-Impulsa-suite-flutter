import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../controllers/tenant_admin_controller.dart';

class BranchContextPage extends StatefulWidget {
  const BranchContextPage({super.key});

  @override
  State<BranchContextPage> createState() => _BranchContextPageState();
}

class _BranchContextPageState extends State<BranchContextPage> {
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
    final filtered = controller.branches.where((branch) {
      final query = _search.toLowerCase();
      return branch.name.toLowerCase().contains(query) ||
          branch.id.toLowerCase().contains(query);
    }).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Contexto de sucursal',
            subtitle:
                'Elige la sucursal que controlará inventario, ventas y restaurante.',
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o ID de sucursal…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (filtered.isEmpty)
            OperationalEmptyState(
              title: 'Sin sucursales',
              message: 'No hay resultados para “$_search”.',
              actionLabel: 'Limpiar búsqueda',
              onAction: () => setState(() => _search = ''),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width < 850 ? 1 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.15,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final branch = filtered[index];
                final selected =
                    context.watch<TenantSessionController>().activeBranchId ==
                    branch.id;
                return Card(
                  color: selected
                      ? AppColors.tenantAccent.withValues(alpha: 0.06)
                      : null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await context
                          .read<TenantSessionController>()
                          .switchBranch(branch.id, branch.name);
                      if (context.mounted) context.go('/app/dashboard');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.store_mall_directory_outlined,
                                color: AppColors.tenantAccent,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  branch.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.tenantAccent,
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '${branch.id} · ${branch.city}',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          Text(branch.address),
                          const SizedBox(height: 10),
                          Text(
                            '${AppFormatters.currency(branch.salesToday)} hoy · ${branch.employees} colaboradores',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
