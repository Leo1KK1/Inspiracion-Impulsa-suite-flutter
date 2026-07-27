import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';

class BranchContextPage extends StatefulWidget {
  const BranchContextPage({super.key});

  @override
  State<BranchContextPage> createState() => _BranchContextPageState();
}

class _BranchContextPageState extends State<BranchContextPage> {
  String _search = '';
  bool _switching = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TenantSessionController>();
    final query = _search.trim().toLowerCase();
    final branches = session.branches
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
            title: 'Contexto de sucursal',
            subtitle: session.canSwitchBranch
                ? 'Elige una sucursal permitida por tu sesión.'
                : 'Tu rol solo puede operar en la sucursal activa.',
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (branches.isEmpty)
            const OperationalEmptyState(
              title: 'Sin sucursales',
              message: 'La sesión no tiene sucursales disponibles.',
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
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];
                final selected = session.activeBranchId == branch.id;
                final enabled =
                    !_switching &&
                    session.canSwitchBranch &&
                    branch.isActive &&
                    !selected;
                return Card(
                  color: selected
                      ? AppColors.tenantAccent.withValues(alpha: 0.06)
                      : null,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: enabled
                        ? () => _switchBranch(context, branch.id)
                        : null,
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
                            branch.code,
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppBadge(
                            label: branch.status,
                            color: branch.isActive
                                ? AppColors.success
                                : AppColors.mutedForeground,
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

  Future<void> _switchBranch(BuildContext context, String branchId) async {
    setState(() => _switching = true);
    final controller = context.read<TenantSessionController>();
    final success = await controller.switchBranch(branchId);
    if (!context.mounted) return;
    setState(() => _switching = false);
    if (success) {
      context.go('/app/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'No fue posible cambiar de sucursal.',
          ),
        ),
      );
    }
  }
}
