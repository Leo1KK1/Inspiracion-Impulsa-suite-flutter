import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../controllers/finance_controller.dart';

class ExpenseCategoriesPage extends StatefulWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  State<ExpenseCategoriesPage> createState() => _ExpenseCategoriesPageState();
}

class _ExpenseCategoriesPageState extends State<ExpenseCategoriesPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    final controller = context.read<FinanceController>();
    if (controller.status == FinanceStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    if (finance.status == FinanceStatus.loading) {
      return const AppLoadingState(message: 'Cargando categorías…');
    }
    final categories = finance.categories
        .where(
          (category) =>
              category.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Categorías de gasto',
            subtitle: 'Presupuestos y reglas para registrar egresos.',
            actions: [
              FilledButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Nueva categoría'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Buscar categoría…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 760 ? 1 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth < 760 ? 1.7 : 1.5,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final color = Color(category.colorValue);
                final usage = category.budgetMonthly == 0
                    ? 0.0
                    : category.spentThisMonth / category.budgetMonthly;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.12),
                              child: Icon(
                                Icons.category_outlined,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            AppBadge(
                              label: category.active ? 'ACTIVA' : 'INACTIVA',
                              color: category.active
                                  ? AppColors.success
                                  : AppColors.mutedForeground,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          category.description,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${AppFormatters.currency(category.spentThisMonth)} de ${AppFormatters.currency(category.budgetMonthly)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 7),
                        LinearProgressIndicator(
                          value: usage.clamp(0, 1),
                          color: usage > 0.9 ? AppColors.destructive : color,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (category.requiresReceipt)
                              const AppBadge(
                                label: 'COMPROBANTE',
                                color: AppColors.primary,
                              ),
                            const SizedBox(width: 6),
                            if (category.requiresApproval)
                              const AppBadge(
                                label: 'APROBACIÓN',
                                color: AppColors.warning,
                              ),
                            const Spacer(),
                            IconButton(
                              tooltip: category.active
                                  ? 'Desactivar'
                                  : 'Activar',
                              onPressed: () =>
                                  _confirmToggle(context, category.name),
                              icon: Icon(
                                category.active
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                color: category.active
                                    ? AppColors.success
                                    : AppColors.mutedForeground,
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

  Future<void> _showForm(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva categoría de gasto'),
        content: const SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'Nombre')),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Presupuesto mensual',
                  prefixText: r'$ ',
                ),
              ),
              SizedBox(height: 12),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('Requiere comprobante'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              AppSuccessFeedback.show(context, 'Categoría guardada en mock.');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(BuildContext context, String name) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cambiar estado de $name'),
        content: const Text(
          'Confirma el cambio. Las categorías inactivas no estarán disponibles en nuevos gastos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              AppSuccessFeedback.show(context, 'Estado actualizado en mock.');
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
