import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../controllers/pos_controller.dart';

class OpenShiftPage extends StatefulWidget {
  const OpenShiftPage({super.key});

  @override
  State<OpenShiftPage> createState() => _OpenShiftPageState();
}

class _OpenShiftPageState extends State<OpenShiftPage> {
  final _cash = TextEditingController(text: '1500');

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ShiftScaffold(
    title: 'Abrir turno de caja',
    subtitle: 'Confirma el fondo inicial antes de iniciar ventas.',
    children: [
      TextField(
        controller: _cash,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Fondo inicial (MXN)',
          prefixText: r'$ ',
        ),
      ),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            context.read<PosController>().openShift();
            AppSuccessFeedback.show(context, 'Turno abierto correctamente.');
            context.go('/app/pos');
          },
          icon: const Icon(Icons.lock_open),
          label: const Text('Abrir turno'),
        ),
      ),
    ],
  );
}

class CloseShiftPage extends StatefulWidget {
  const CloseShiftPage({super.key});

  @override
  State<CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<CloseShiftPage> {
  final _counted = TextEditingController();

  @override
  void dispose() {
    _counted.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const expected = 4382.50;
    final counted = double.tryParse(_counted.text) ?? 0;
    final difference = counted - expected;
    return _ShiftScaffold(
      title: 'Cierre de turno',
      subtitle: 'Turno T-2024-0041 · abierto a las 09:02.',
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: const [
            _ShiftMetric('Ventas totales', r'$9,602.50'),
            _ShiftMetric('Tickets', '47'),
            _ShiftMetric('Ticket promedio', r'$204.31'),
            _ShiftMetric('Cancelaciones', '2 · \$340.00'),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _counted,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Conteo físico de efectivo',
            prefixText: r'$ ',
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          tileColor: difference.abs() < 0.01
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.warning.withValues(alpha: 0.1),
          title: const Text('Efectivo esperado'),
          subtitle: const Text('\$4,382.50'),
          trailing: Text(
            'Diferencia ${AppFormatters.currency(difference)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: counted <= 0
                ? null
                : () {
                    context.read<PosController>().closeShift();
                    AppSuccessFeedback.show(context, 'Turno cerrado.');
                    context.go('/app/dashboard');
                  },
            icon: const Icon(Icons.lock_outline),
            label: const Text('Confirmar cierre'),
          ),
        ),
      ],
    );
  }
}

class _ShiftScaffold extends StatelessWidget {
  const _ShiftScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
                const Divider(height: 32),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ShiftMetric extends StatelessWidget {
  const _ShiftMetric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.background,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    ),
  );
}
