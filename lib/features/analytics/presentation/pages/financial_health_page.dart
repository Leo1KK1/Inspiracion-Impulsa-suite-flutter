import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../finance/data/models/finance_models.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';

class FinancialHealthPage extends StatefulWidget {
  const FinancialHealthPage({super.key});

  @override
  State<FinancialHealthPage> createState() => _FinancialHealthPageState();
}

class _FinancialHealthPageState extends State<FinancialHealthPage> {
  @override
  void initState() {
    super.initState();
    final finance = context.read<FinanceController>();
    if (finance.status == FinanceStatus.idle) finance.load();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    if (finance.status == FinanceStatus.loading &&
        finance.branchComparison == null) {
      return const AppLoadingState(message: 'Consultando salud financiera…');
    }
    if (finance.status == FinanceStatus.error &&
        finance.branchComparison == null) {
      return AppErrorState(
        message: finance.errorMessage ?? 'No fue posible cargar el reporte.',
        onRetry: () => finance.load(force: true),
      );
    }

    final comparison = finance.branchComparison;
    final profit = finance.netProfit;
    if (comparison == null || profit == null) {
      return const OperationalEmptyState(
        title: 'Sin información financiera',
        message: 'El backend no devolvió datos para este periodo.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Salud financiera',
            subtitle:
                'Utilidad operativa y comparación real por sucursal, sin '
                'scores estimados por el frontend.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _pickRange(context, finance),
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${AppFormatters.date(finance.from)} — '
                  '${AppFormatters.date(finance.to)}',
                ),
              ),
            ],
          ),
          if (finance.status == FinanceStatus.loading)
            const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 18),
          _NetProfitCard(report: profit),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 760 ? 1 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth < 760 ? 1.8 : 1.55,
              ),
              itemCount: comparison.branches.length,
              itemBuilder: (context, index) =>
                  _BranchHealthCard(branch: comparison.branches[index]),
            ),
          ),
          if (comparison.viewerRole == 'MANAGER' &&
              comparison.branches.any((branch) => branch.masked)) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.primary.withValues(alpha: 0.06),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El backend protege el alcance MANAGER: únicamente la '
                        'sucursal activa muestra importes reales; las demás '
                        'filas llegan con masked=true.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _NetProfitCard extends StatelessWidget {
  const _NetProfitCard({required this.report});

  final NetProfitReport report;

  @override
  Widget build(BuildContext context) {
    final positive = report.netProfit >= 0;
    final color = positive ? AppColors.success : AppColors.destructive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 28,
          runSpacing: 18,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              positive ? Icons.trending_up : Icons.trending_down,
              size: 46,
              color: color,
            ),
            SizedBox(
              width: 230,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Utilidad neta operativa'),
                  Text(
                    AppFormatters.currency(report.netProfit),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: color),
                  ),
                  AppBadge(
                    label: positive ? 'POSITIVA' : 'DÉFICIT',
                    color: color,
                  ),
                ],
              ),
            ),
            _Metric(
              label: 'Ingresos',
              value: AppFormatters.currency(report.income),
            ),
            _Metric(
              label: 'Gastos',
              value: AppFormatters.currency(report.expenses),
            ),
            SizedBox(
              width: 300,
              child: Text(
                report.formula,
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchHealthCard extends StatelessWidget {
  const _BranchHealthCard({required this.branch});

  final BranchFinancialComparison branch;

  @override
  Widget build(BuildContext context) {
    if (branch.masked) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 42,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text(
                branch.branchName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(branch.branchCode),
              const SizedBox(height: 8),
              const AppBadge(
                label: 'DATOS ENMASCARADOS',
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      );
    }

    final positive = branch.netProfit >= 0;
    final color = positive ? AppColors.success : AppColors.destructive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(
                    positive ? Icons.trending_up : Icons.trending_down,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.branchName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        branch.branchCode,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                AppBadge(
                  label: positive ? 'POSITIVA' : 'DÉFICIT',
                  color: color,
                ),
              ],
            ),
            const Divider(height: 28),
            _Metric(
              label: 'Ventas',
              value: AppFormatters.currency(branch.income),
              detail: '${branch.salesCount} operaciones',
            ),
            const SizedBox(height: 8),
            _Metric(
              label: 'Gastos',
              value: AppFormatters.currency(branch.expenses),
              detail: '${branch.expensesCount} registros',
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'Utilidad ${AppFormatters.currency(branch.netProfit)}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
                const Spacer(),
                Text('${branch.margin.toStringAsFixed(1)}% margen'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedForeground)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        if (detail != null)
          Text(
            detail!,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
      ],
    ),
  );
}
