import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../../data/models/finance_models.dart';
import '../controllers/finance_controller.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/expense_status_badge.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<FinanceController>();
    if (controller.status == FinanceStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final session = context.watch<TenantSessionController>();
    if (finance.status == FinanceStatus.loading && finance.expenses.isEmpty) {
      return const AppLoadingState(message: 'Cargando gastos…');
    }
    if (finance.status == FinanceStatus.error && finance.expenses.isEmpty) {
      return AppErrorState(
        message: finance.errorMessage ?? 'No fue posible cargar gastos.',
        onRetry: () => finance.load(force: true),
      );
    }

    final expenses = finance.filteredExpenses;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Gastos operativos',
            subtitle:
                'Registros reales por periodo, categoría y alcance de sucursal.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _pickRange(context, finance),
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${AppFormatters.date(finance.from)} — '
                  '${AppFormatters.date(finance.to)}',
                ),
              ),
              FilledButton.icon(
                onPressed: finance.saving
                    ? null
                    : () => showDialog<bool>(
                        context: context,
                        builder: (_) => const ExpenseFormDialog(),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo gasto'),
              ),
            ],
          ),
          if (finance.status == FinanceStatus.loading)
            const LinearProgressIndicator(minHeight: 2),
          if (finance.errorMessage != null) ...[
            const SizedBox(height: 12),
            MaterialBanner(
              content: Text(finance.errorMessage!),
              leading: const Icon(
                Icons.error_outline,
                color: AppColors.destructive,
              ),
              actions: [
                TextButton(
                  onPressed: finance.clearError,
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  onChanged: finance.setQuery,
                  decoration: const InputDecoration(
                    hintText: 'Buscar ID, notas, categoría o sucursal…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              _StringFilter(
                key: ValueKey(
                  'category:${finance.selectedCategoryId ?? '_all'}',
                ),
                label: 'Categoría',
                value: finance.selectedCategoryId ?? '_all',
                items: {
                  '_all': 'Todas',
                  for (final category in finance.categoryOptions)
                    category.id: category.name,
                },
                onChanged: (value) =>
                    finance.setCategoryFilter(value == '_all' ? null : value),
              ),
              if (finance.isOwner)
                _StringFilter(
                  key: ValueKey('branch:${finance.selectedBranchId ?? '_all'}'),
                  label: 'Sucursal',
                  value: finance.selectedBranchId ?? '_all',
                  items: {
                    '_all': 'Todas + globales',
                    for (final branch in session.branches.where(
                      (item) => item.isActive,
                    ))
                      branch.id: branch.name,
                  },
                  onChanged: (value) =>
                      finance.setBranchFilter(value == '_all' ? null : value),
                )
              else
                _ReadOnlyFilter(
                  label: 'Sucursal',
                  value: session.session?.activeBranchName ?? 'Sucursal activa',
                ),
              _StringFilter(
                key: ValueKey(
                  'status:${finance.selectedExpenseStatus?.apiValue ?? '_all'}',
                ),
                label: 'Estado',
                value: finance.selectedExpenseStatus?.apiValue ?? '_all',
                items: const {
                  '_all': 'Todos',
                  'RECORDED': 'Registrados',
                  'CANCELLED': 'Cancelados',
                },
                onChanged: (value) => finance.setStatusFilter(switch (value) {
                  'RECORDED' => ExpenseStatus.recorded,
                  'CANCELLED' => ExpenseStatus.cancelled,
                  _ => null,
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            const OperationalEmptyState(
              title: 'Sin gastos',
              message:
                  'El backend no devolvió registros para los filtros '
                  'seleccionados.',
            )
          else
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Notas')),
                    DataColumn(label: Text('Categoría')),
                    DataColumn(label: Text('Sucursal')),
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Monto'), numeric: true),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final expense in expenses)
                      DataRow(
                        cells: [
                          DataCell(
                            Tooltip(
                              message: expense.id,
                              child: Text(_shortId(expense.id)),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 250,
                              child: Text(
                                expense.notes?.trim().isNotEmpty == true
                                    ? expense.notes!
                                    : 'Sin notas',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(expense.category.name)),
                          DataCell(Text(expense.branchLabel)),
                          DataCell(
                            Text(AppFormatters.date(expense.expenseDate)),
                          ),
                          DataCell(Text(expense.expenseType.label)),
                          DataCell(
                            Text(AppFormatters.currency(expense.amount)),
                          ),
                          DataCell(ExpenseStatusBadge(status: expense.status)),
                          DataCell(
                            IconButton(
                              onPressed: () => context.go(
                                '/app/admin/finance/expenses/${expense.id}',
                              ),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    FinanceController finance,
  ) async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: finance.from, end: finance.to),
    );
    if (selected != null) {
      await finance.setDateRange(selected.start, selected.end);
    }
  }
}

class _StringFilter extends StatelessWidget {
  const _StringFilter({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in items.entries)
          DropdownMenuItem(value: item.key, child: Text(item.value)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}

class _ReadOnlyFilter extends StatelessWidget {
  const _ReadOnlyFilter({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value, overflow: TextOverflow.ellipsis),
    ),
  );
}

String _shortId(String value) =>
    value.length <= 10 ? value : '${value.substring(0, 10)}…';
