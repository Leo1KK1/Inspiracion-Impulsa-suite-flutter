import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/finance_models.dart';
import '../controllers/finance_controller.dart';
import '../widgets/expense_status_badge.dart';

class ExpenseDetailPage extends StatelessWidget {
  const ExpenseDetailPage({super.key, required this.expenseId});
  final String expenseId;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    if (finance.status == FinanceStatus.idle) {
      Future.microtask(finance.load);
      return const AppLoadingState(message: 'Cargando gasto…');
    }
    final expense = finance.expenses
        .where((item) => item.id == expenseId)
        .firstOrNull;
    if (expense == null) {
      return OperationalEmptyState(
        title: 'Gasto no encontrado',
        message: 'El gasto solicitado no existe.',
        actionLabel: 'Volver a gastos',
        onAction: () => context.go('/app/admin/finance/expenses'),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: expense.folio,
            subtitle: expense.concept,
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/app/admin/finance/expenses'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Gastos'),
              ),
              if (expense.status != ExpenseStatus.cancelled)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                  ),
                  onPressed: () => _confirmVoid(context, finance, expense),
                  icon: const Icon(Icons.block),
                  label: const Text('Anular'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width < 850 ? 1 : 3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.1,
            children: [
              MetricCard(
                label: 'Monto base',
                value: AppFormatters.currency(expense.amount),
                icon: Icons.payments_outlined,
              ),
              MetricCard(
                label: 'IVA',
                value: AppFormatters.currency(expense.tax),
                icon: Icons.receipt_outlined,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Impacto total',
                value: AppFormatters.currency(expense.total),
                icon: Icons.trending_down,
                color: AppColors.destructive,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Detalle',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      ExpenseStatusBadge(status: expense.status),
                    ],
                  ),
                  const Divider(height: 28),
                  _Info('Categoría', expense.category),
                  _Info('Sucursal', expense.branchId),
                  _Info('Fecha', AppFormatters.date(expense.date)),
                  _Info('Método', expense.method.name.toUpperCase()),
                  _Info('Creado por', expense.createdBy),
                  _Info('Notas', expense.notes),
                  _Info(
                    'Comprobante',
                    expense.hasReceipt
                        ? 'factura_${expense.folio.toLowerCase()}.pdf'
                        : 'Sin comprobante',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmVoid(
    BuildContext context,
    FinanceController finance,
    Expense expense,
  ) async {
    final typed = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anular gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esta acción no puede deshacerse. Escribe ${expense.folio} para confirmar.',
            ),
            const SizedBox(height: 14),
            TextField(controller: typed),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            onPressed: () {
              if (typed.text != expense.folio) return;
              finance.voidExpense(expense.id);
              Navigator.pop(dialogContext);
              AppSuccessFeedback.show(context, 'Gasto anulado.');
            },
            child: const Text('Anular gasto'),
          ),
        ],
      ),
    );
    typed.dispose();
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
