import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
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
  final Map<String, Set<String>> _assignments = {};

  @override
  void initState() {
    super.initState();
    final controller = context.read<TenantAdminController>();
    if (controller.status == TenantAdminStatus.idle) controller.load();
    for (final employee in controller.employees) {
      _assignments[employee.id] = employee.branchIds.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TenantAdminController>();
    if (controller.status == TenantAdminStatus.loading) {
      return const AppLoadingState(message: 'Cargando matriz de acceso…');
    }
    for (final employee in controller.employees) {
      _assignments.putIfAbsent(employee.id, () => employee.branchIds.toSet());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Controlador Maestro Multisucursal',
            subtitle: 'Asigna acceso de cada colaborador a las sucursales.',
            actions: [
              FilledButton.icon(
                onPressed: () =>
                    AppSuccessFeedback.show(context, 'Asignaciones guardadas.'),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Colaborador')),
                    for (final branch in controller.branches)
                      DataColumn(label: Text(branch.id)),
                  ],
                  rows: [
                    for (final employee in controller.employees)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(employee.name),
                                subtitle: Text(employee.role),
                              ),
                            ),
                          ),
                          for (final branch in controller.branches)
                            DataCell(
                              Checkbox(
                                value:
                                    _assignments[employee.id]?.contains(
                                      branch.id,
                                    ) ??
                                    false,
                                onChanged: (checked) {
                                  setState(() {
                                    final set = _assignments[employee.id]!;
                                    if (checked ?? false) {
                                      set.add(branch.id);
                                    } else {
                                      set.remove(branch.id);
                                    }
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Los cambios se aplican al volver a autenticar o refrescar la sesión.',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
