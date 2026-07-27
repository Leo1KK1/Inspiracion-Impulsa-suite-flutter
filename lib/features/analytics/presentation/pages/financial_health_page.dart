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
    final controller = context.read<FinanceController>();
    if (controller.status == FinanceStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    if (finance.status == FinanceStatus.loading) {
      return const AppLoadingState(message: 'Evaluando salud financiera…');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Salud financiera',
            subtitle: 'Score, margen, estabilidad y riesgos por sucursal.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth < 720 ? 1 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: constraints.maxWidth < 720 ? 1.75 : 1.55,
              ),
              itemCount: finance.health.length,
              itemBuilder: (context, index) {
                final branch = finance.health[index];
                final color = _color(branch.status);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.square(
                                  dimension: 74,
                                  child: CircularProgressIndicator(
                                    value: branch.score / 100,
                                    strokeWidth: 8,
                                    color: color,
                                    backgroundColor: color.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${branch.score}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    branch.id,
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  AppBadge(
                                    label: _label(branch.status),
                                    color: color,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        _Indicator(
                          'Margen operativo',
                          branch.margin,
                          50,
                          color,
                        ),
                        _Indicator('Estabilidad', branch.stability, 100, color),
                        const Spacer(),
                        Text(
                          '${AppFormatters.compactCurrency(branch.revenue)} ventas · ${AppFormatters.compactCurrency(branch.expenses)} gastos',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.warning.withValues(alpha: 0.06),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.warning),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'MTY-01 requiere atención: el gasto crece 9.1% y su margen cayó debajo de 25%. Revisa nómina, servicios y precios.',
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

  Color _color(FinancialHealthStatus status) => switch (status) {
    FinancialHealthStatus.healthy => AppColors.success,
    FinancialHealthStatus.atRisk => AppColors.warning,
    FinancialHealthStatus.critical => AppColors.destructive,
  };

  String _label(FinancialHealthStatus status) => switch (status) {
    FinancialHealthStatus.healthy => 'SALUDABLE',
    FinancialHealthStatus.atRisk => 'EN RIESGO',
    FinancialHealthStatus.critical => 'CRÍTICO',
  };
}

class _Indicator extends StatelessWidget {
  const _Indicator(this.label, this.value, this.max, this.color);
  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Column(
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: (value / max).clamp(0, 1),
          color: color,
          minHeight: 7,
          borderRadius: BorderRadius.circular(99),
        ),
      ],
    ),
  );
}
