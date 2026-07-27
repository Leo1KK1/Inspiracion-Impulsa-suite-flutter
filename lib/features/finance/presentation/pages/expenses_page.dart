import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../controllers/finance_controller.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/expense_status_badge.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  String _query = '';
  String _category = 'Todas';
  String _branch = 'Todas';

  @override
  void initState() {
    super.initState();
    final controller = context.read<FinanceController>();
    if (controller.status == FinanceStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceController>();
    if (controller.status == FinanceStatus.loading) {
      return const AppLoadingState(message: 'Cargando gastos…');
    }
    if (controller.status == FinanceStatus.error) {
      return AppErrorState(
        message: controller.errorMessage!,
        onRetry: controller.load,
      );
    }
    final expenses = controller.expenses.where((expense) {
      final matchesText =
          expense.concept.toLowerCase().contains(_query.toLowerCase()) ||
          expense.folio.toLowerCase().contains(_query.toLowerCase());
      return matchesText &&
          (_category == 'Todas' || expense.category == _category) &&
          (_branch == 'Todas' || expense.branchId == _branch);
    }).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Gastos operativos',
            subtitle: 'Control de egresos y comprobantes por sucursal.',
            actions: [
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ExpenseFormDialog(),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo gasto'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 310,
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar concepto o folio…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              _Filter(
                label: 'Categoría',
                value: _category,
                items: const [
                  'Todas',
                  'Renta',
                  'Nómina',
                  'Servicios',
                  'Mantenimiento',
                  'Marketing',
                  'Uniformes',
                  'Tecnología',
                ],
                onChanged: (value) => setState(() => _category = value),
              ),
              _Filter(
                label: 'Sucursal',
                value: _branch,
                items: const [
                  'Todas',
                  'CDMX-01',
                  'CDMX-02',
                  'GDL-01',
                  'MTY-01',
                ],
                onChanged: (value) => setState(() => _branch = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            OperationalEmptyState(
              title: 'Sin gastos',
              message: 'No hay registros con los filtros seleccionados.',
              actionLabel: 'Limpiar filtros',
              onAction: () => setState(() {
                _query = '';
                _category = 'Todas';
                _branch = 'Todas';
              }),
            )
          else
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Folio')),
                    DataColumn(label: Text('Concepto')),
                    DataColumn(label: Text('Categoría')),
                    DataColumn(label: Text('Sucursal')),
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Monto'), numeric: true),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Comprobante')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (final expense in expenses)
                      DataRow(
                        cells: [
                          DataCell(Text(expense.folio)),
                          DataCell(
                            SizedBox(width: 250, child: Text(expense.concept)),
                          ),
                          DataCell(Text(expense.category)),
                          DataCell(Text(expense.branchId)),
                          DataCell(Text(AppFormatters.date(expense.date))),
                          DataCell(Text(AppFormatters.currency(expense.total))),
                          DataCell(ExpenseStatusBadge(status: expense.status)),
                          DataCell(
                            Icon(
                              expense.hasReceipt
                                  ? Icons.attach_file
                                  : Icons.remove,
                            ),
                          ),
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
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) => onChanged(value ?? items.first),
    ),
  );
}
