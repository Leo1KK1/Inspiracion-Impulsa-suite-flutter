import 'package:fl_chart/fl_chart.dart';
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
import '../../../session/presentation/controllers/tenant_session_controller.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  @override
  void initState() {
    super.initState();
    final finance = context.read<FinanceController>();
    if (finance.status == FinanceStatus.idle) finance.load();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final session = context.watch<TenantSessionController>();
    if (finance.status == FinanceStatus.loading && finance.summary == null) {
      return const AppLoadingState(message: 'Calculando analítica…');
    }
    if (finance.status == FinanceStatus.error && finance.summary == null) {
      return AppErrorState(
        message: finance.errorMessage ?? 'No fue posible cargar analítica.',
        onRetry: () => finance.load(force: true),
      );
    }
    final summary = finance.summary;
    final report = finance.salesVsExpenses;
    final comparison = finance.branchComparison;
    if (summary == null || report == null || comparison == null) {
      return const OperationalEmptyState(
        title: 'Sin analítica',
        message: 'El backend no devolvió datos para el periodo.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dashboard financiero',
            subtitle:
                'Ventas COMPLETED y gastos RECORDED calculados por el backend.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _pickRange(context, finance),
                icon: const Icon(Icons.date_range),
                label: Text(
                  '${AppFormatters.date(finance.from)} — '
                  '${AppFormatters.date(finance.to)}',
                ),
              ),
              if (finance.isOwner)
                _BranchFilter(
                  selectedBranchId: finance.selectedBranchId,
                  branches: session.branches
                      .where((branch) => branch.isActive)
                      .map((branch) => MapEntry(branch.id, branch.name))
                      .toList(growable: false),
                  onChanged: finance.setBranchFilter,
                )
              else
                _ScopeLabel(
                  value: session.session?.activeBranchName ?? 'Sucursal activa',
                ),
            ],
          ),
          if (finance.status == FinanceStatus.loading)
            const LinearProgressIndicator(minHeight: 2),
          if (finance.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              finance.errorMessage!,
              style: const TextStyle(color: AppColors.destructive),
            ),
          ],
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: _columns(MediaQuery.sizeOf(context).width),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 13,
            mainAxisSpacing: 13,
            childAspectRatio: 2.1,
            children: [
              MetricCard(
                label: 'Ventas nominales',
                value: AppFormatters.compactCurrency(
                  summary.income.totalSalesNominal,
                ),
                detail: '${summary.income.salesCount} ventas',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              MetricCard(
                label: 'Cobrado real',
                value: AppFormatters.compactCurrency(
                  summary.income.totalCollectedReal,
                ),
                detail: 'Confirmado por pagos',
                icon: Icons.account_balance_wallet_outlined,
              ),
              MetricCard(
                label: 'Gastos operativos',
                value: AppFormatters.compactCurrency(
                  summary.expenses.totalExpenses,
                ),
                detail: '${summary.expenses.expensesCount} gastos',
                icon: Icons.trending_down,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Utilidad neta',
                value: AppFormatters.compactCurrency(summary.netProfit),
                detail: summary.netProfit >= 0 ? 'Positiva' : 'Déficit',
                icon: Icons.payments_outlined,
                color: summary.netProfit >= 0
                    ? AppColors.success
                    : AppColors.destructive,
              ),
              MetricCard(
                label: 'Ticket promedio',
                value: AppFormatters.currency(summary.ticketAverage),
                detail: 'Calculado por backend',
                icon: Icons.receipt_long_outlined,
              ),
              MetricCard(
                label: 'Margen operativo',
                value: '${summary.operatingMargin.toStringAsFixed(1)}%',
                detail: 'Utilidad / ventas',
                icon: Icons.query_stats,
                color: summary.operatingMargin >= 0
                    ? AppColors.primary
                    : AppColors.destructive,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SalesExpenseChart(report: report),
          const SizedBox(height: 16),
          _BranchComparison(report: comparison),
          const SizedBox(height: 16),
          Card(
            color:
                (summary.netProfit >= 0
                        ? AppColors.success
                        : AppColors.destructive)
                    .withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    summary.netProfit >= 0
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: summary.netProfit >= 0
                        ? AppColors.success
                        : AppColors.destructive,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Resultado del periodo: '
                      '${AppFormatters.currency(summary.netProfit)}. '
                      'Ingresos y egresos provienen de los endpoints de '
                      'analítica; el frontend solo presenta el resultado.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _columns(double width) => width < 700
      ? 1
      : width < 1280
      ? 2
      : 3;

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

class _SalesExpenseChart extends StatelessWidget {
  const _SalesExpenseChart({required this.report});

  final SalesVsExpensesReport report;

  @override
  Widget build(BuildContext context) {
    final dates = <DateTime>{
      ...report.incomeByDay.map((item) => _day(item.date)),
      ...report.expensesByDay.map((item) => _day(item.date)),
    }.toList()..sort();
    final income = {
      for (final item in report.incomeByDay) _day(item.date): item.total,
    };
    final expenses = {
      for (final item in report.expensesByDay) _day(item.date): item.total,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ventas vs gastos por día',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 18,
              children: [
                _Legend(label: 'Ventas', color: AppColors.primary),
                _Legend(label: 'Gastos', color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 18),
            if (dates.isEmpty)
              const SizedBox(
                height: 220,
                child: OperationalEmptyState(
                  title: 'Sin movimientos',
                  message: 'No hay series diarias para el periodo.',
                ),
              )
            else ...[
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: dates.length > 8
                              ? (dates.length / 6).ceilToDouble()
                              : 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= dates.length) {
                              return const SizedBox.shrink();
                            }
                            final date = dates[index];
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                '${date.day}/${date.month}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 54,
                        ),
                      ),
                    ),
                    lineBarsData: [
                      _line(dates, income, AppColors.primary),
                      _line(dates, expenses, AppColors.warning),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Ventas'), numeric: true),
                    DataColumn(label: Text('Gastos'), numeric: true),
                  ],
                  rows: [
                    for (final date in dates)
                      DataRow(
                        cells: [
                          DataCell(Text(AppFormatters.date(date))),
                          DataCell(
                            Text(AppFormatters.currency(income[date] ?? 0)),
                          ),
                          DataCell(
                            Text(AppFormatters.currency(expenses[date] ?? 0)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LineChartBarData _line(
    List<DateTime> dates,
    Map<DateTime, double> values,
    Color color,
  ) => LineChartBarData(
    spots: [
      for (var index = 0; index < dates.length; index++)
        FlSpot(index.toDouble(), values[dates[index]] ?? 0),
    ],
    color: color,
    isCurved: true,
    barWidth: 3,
    dotData: const FlDotData(show: true),
  );
}

class _BranchComparison extends StatelessWidget {
  const _BranchComparison({required this.report});

  final BranchComparisonReport report;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparación por sucursal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            report.viewerRole == 'MANAGER'
                ? 'Las otras sucursales aparecen enmascaradas por el backend.'
                : 'Vista consolidada de sucursales activas.',
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Sucursal')),
                DataColumn(label: Text('Ventas'), numeric: true),
                DataColumn(label: Text('Gastos'), numeric: true),
                DataColumn(label: Text('Utilidad'), numeric: true),
                DataColumn(label: Text('Estado')),
              ],
              rows: [
                for (final branch in report.branches)
                  DataRow(
                    cells: [
                      DataCell(
                        Text('${branch.branchName} · ${branch.branchCode}'),
                      ),
                      DataCell(
                        Text(
                          branch.masked
                              ? 'Oculto'
                              : AppFormatters.currency(branch.income),
                        ),
                      ),
                      DataCell(
                        Text(
                          branch.masked
                              ? 'Oculto'
                              : AppFormatters.currency(branch.expenses),
                        ),
                      ),
                      DataCell(
                        Text(
                          branch.masked
                              ? 'Oculto'
                              : AppFormatters.currency(branch.netProfit),
                        ),
                      ),
                      DataCell(
                        AppBadge(
                          label: branch.masked
                              ? 'ENMASCARADO'
                              : branch.netProfit >= 0
                              ? 'POSITIVA'
                              : 'DÉFICIT',
                          color: branch.masked
                              ? AppColors.mutedForeground
                              : branch.netProfit >= 0
                              ? AppColors.success
                              : AppColors.destructive,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 12, color: color),
      const SizedBox(width: 6),
      Text(label),
    ],
  );
}

class _BranchFilter extends StatelessWidget {
  const _BranchFilter({
    required this.selectedBranchId,
    required this.branches,
    required this.onChanged,
  });

  final String? selectedBranchId;
  final List<MapEntry<String, String>> branches;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: DropdownButtonFormField<String>(
      key: ValueKey(selectedBranchId),
      initialValue: selectedBranchId ?? '_all',
      decoration: const InputDecoration(labelText: 'Alcance'),
      items: [
        const DropdownMenuItem(
          value: '_all',
          child: Text('Consolidado tenant'),
        ),
        for (final branch in branches)
          DropdownMenuItem(value: branch.key, child: Text(branch.value)),
      ],
      onChanged: (value) =>
          onChanged(value == null || value == '_all' ? null : value),
    ),
  );
}

class _ScopeLabel extends StatelessWidget {
  const _ScopeLabel({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: InputDecorator(
      decoration: const InputDecoration(labelText: 'Alcance MANAGER'),
      child: Text(value, overflow: TextOverflow.ellipsis),
    ),
  );
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
