import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';

class AnalyticsDashboardPage extends StatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  State<AnalyticsDashboardPage> createState() => _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState extends State<AnalyticsDashboardPage> {
  String _period = 'Septiembre 2025';
  String _branch = 'Todas las sucursales';
  static const sales = [
    480.0,
    520.0,
    495.0,
    610.0,
    578.0,
    643.0,
    598.0,
    671.0,
    724.0,
  ];
  static const expenses = [
    310.0,
    325.0,
    302.0,
    358.0,
    341.0,
    370.0,
    349.0,
    388.0,
    402.0,
  ];

  @override
  void initState() {
    super.initState();
    final finance = context.read<FinanceController>();
    if (finance.status == FinanceStatus.idle) finance.load();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    if (finance.status == FinanceStatus.loading) {
      return const AppLoadingState(message: 'Calculando analítica…');
    }
    const revenue = 724000.0;
    const expense = 402000.0;
    const profit = revenue - expense;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dashboard financiero',
            subtitle: 'Ventas, gastos y utilidad por periodo y sucursal.',
            actions: [
              _Filter(
                value: _period,
                items: const [
                  'Septiembre 2025',
                  'Agosto 2025',
                  'Q3 2025',
                  'YTD 2025',
                ],
                onChanged: (value) => setState(() => _period = value),
              ),
              _Filter(
                value: _branch,
                items: const [
                  'Todas las sucursales',
                  'CDMX-01',
                  'CDMX-02',
                  'GDL-01',
                  'MTY-01',
                ],
                onChanged: (value) => setState(() => _branch = value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: _columns(MediaQuery.sizeOf(context).width),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 13,
            mainAxisSpacing: 13,
            childAspectRatio: 2.2,
            children: const [
              MetricCard(
                label: 'Ingresos',
                value: r'$724K',
                detail: '+8.1%',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              MetricCard(
                label: 'Gastos operativos',
                value: r'$402K',
                detail: '+5.2%',
                icon: Icons.trending_down,
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Utilidad neta',
                value: r'$322K',
                detail: 'Positiva',
                icon: Icons.payments_outlined,
              ),
              MetricCard(
                label: 'Margen operativo',
                value: '44.4%',
                detail: '+1.2 pp',
                icon: Icons.query_stats,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = const _SalesExpenseChart(
                sales: sales,
                expenses: expenses,
              );
              final alerts = const _FinancialAlerts();
              if (constraints.maxWidth < 920) {
                return Column(
                  children: [chart, const SizedBox(height: 16), alerts],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _SalesExpenseChart(sales: sales, expenses: expenses),
                  ),
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: _FinancialAlerts()),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparación por sucursal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  for (final item in finance.health)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      subtitle: LinearProgressIndicator(
                        value: item.margin / 50,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      trailing: Text(
                        '${item.margin}% margen',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text('Resultado: utilidad ${profit > 0 ? 'positiva' : 'negativa'}'),
        ],
      ),
    );
  }

  int _columns(double width) => width < 700
      ? 1
      : width < 1280
      ? 2
      : 4;
}

class _SalesExpenseChart extends StatelessWidget {
  const _SalesExpenseChart({required this.sales, required this.expenses});
  final List<double> sales;
  final List<double> expenses;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas vs gastos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                ),
                lineBarsData: [
                  _line(sales, AppColors.primary),
                  _line(expenses, AppColors.warning),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  LineChartBarData _line(List<double> values, Color color) => LineChartBarData(
    spots: [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ],
    color: color,
    isCurved: true,
    barWidth: 3,
    dotData: const FlDotData(show: false),
  );
}

class _FinancialAlerts extends StatelessWidget {
  const _FinancialAlerts();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alertas financieras',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const _Alert(
            'Gasto de nómina supera 42% del ingreso en MTY-01',
            AppColors.destructive,
          ),
          const _Alert(
            'Margen operativo de GDL-01 cayó 4.2 pp',
            AppColors.warning,
          ),
          const _Alert(
            'Utilidad neta de CDMX-01 mejoró +8.1%',
            AppColors.success,
          ),
        ],
      ),
    ),
  );
}

class _Alert extends StatelessWidget {
  const _Alert(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(Icons.circle, color: color, size: 12),
    title: Text(text),
  );
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) => onChanged(value ?? items.first),
    ),
  );
}
