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
import '../widgets/expense_form_dialog.dart';
import '../widgets/expense_status_badge.dart';

class ExpenseDetailPage extends StatefulWidget {
  const ExpenseDetailPage({super.key, required this.expenseId});

  final String expenseId;

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<FinanceController>().loadExpense(widget.expenseId),
    );
  }

  @override
  void didUpdateWidget(covariant ExpenseDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseId != widget.expenseId) {
      context.read<FinanceController>().loadExpense(widget.expenseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    if (finance.loadingExpense) {
      return const AppLoadingState(message: 'Cargando gasto…');
    }
    final expense = finance.selectedExpense?.id == widget.expenseId
        ? finance.selectedExpense
        : null;
    if (expense == null) {
      if (finance.errorMessage != null) {
        return AppErrorState(
          message: finance.errorMessage!,
          onRetry: () => finance.loadExpense(widget.expenseId),
        );
      }
      return OperationalEmptyState(
        title: 'Gasto no encontrado',
        message: 'El backend no devolvió el gasto solicitado.',
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
            title: 'Gasto ${_shortId(expense.id)}',
            subtitle:
                '${expense.category.name} · ${expense.branchLabel} · '
                '${AppFormatters.date(expense.expenseDate)}',
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/app/admin/finance/expenses'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Gastos'),
              ),
              if (!expense.isCancelled)
                OutlinedButton.icon(
                  onPressed: finance.saving
                      ? null
                      : () => showDialog<bool>(
                          context: context,
                          builder: (_) => ExpenseFormDialog(expense: expense),
                        ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              if (!expense.isCancelled)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                  ),
                  onPressed: finance.saving
                      ? null
                      : () => _confirmCancel(context, finance, expense),
                  icon: const Icon(Icons.block),
                  label: const Text('Cancelar gasto'),
                ),
            ],
          ),
          if (finance.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              finance.errorMessage!,
              style: const TextStyle(color: AppColors.destructive),
            ),
          ],
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
                label: 'Monto registrado',
                value: AppFormatters.currency(expense.amount),
                icon: Icons.payments_outlined,
              ),
              MetricCard(
                label: 'Tipo',
                value: expense.expenseType.label,
                icon: Icons.tune,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Alcance',
                value: expense.branchLabel,
                icon: expense.isGlobal ? Icons.public : Icons.store_outlined,
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
                        'Detalle del backend',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      ExpenseStatusBadge(status: expense.status),
                    ],
                  ),
                  const Divider(height: 28),
                  _Info('ID', expense.id),
                  _Info(
                    'Categoría',
                    '${expense.category.name} · ${expense.category.code}',
                  ),
                  _Info('Sucursal', expense.branchLabel),
                  _Info('Fecha', AppFormatters.date(expense.expenseDate)),
                  _Info('Tipo', expense.expenseType.label),
                  _Info(
                    'Notas',
                    expense.notes?.trim().isNotEmpty == true
                        ? expense.notes!
                        : 'Sin notas',
                  ),
                  _Info(
                    'Creado',
                    expense.createdAt == null
                        ? 'Sin fecha'
                        : AppFormatters.date(expense.createdAt!),
                  ),
                  _Info(
                    'Actualizado',
                    expense.updatedAt == null
                        ? 'Sin fecha'
                        : AppFormatters.date(expense.updatedAt!),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    FinanceController finance,
    Expense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar gasto'),
        content: const Text(
          'El backend conservará el registro y cambiará su estado a '
          'CANCELLED. Dejará de participar en los indicadores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancelar gasto'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await finance.cancelExpense(expense.id);
    if (!context.mounted || !success) return;
    AppSuccessFeedback.show(context, 'Gasto cancelado correctamente.');
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

String _shortId(String value) =>
    value.length <= 10 ? value : '${value.substring(0, 10)}…';
