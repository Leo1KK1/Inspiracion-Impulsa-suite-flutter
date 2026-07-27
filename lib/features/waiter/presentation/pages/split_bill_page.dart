import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/waiter_models.dart';
import '../controllers/waiter_controller.dart';

enum _SplitMode { equal, products }

class SplitBillPage extends StatefulWidget {
  const SplitBillPage({super.key, required this.tableId});

  final String tableId;

  @override
  State<SplitBillPage> createState() => _SplitBillPageState();
}

class _SplitBillPageState extends State<SplitBillPage> {
  _SplitMode _mode = _SplitMode.equal;
  int _people = 2;
  final Map<String, int> _assignments = {};
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterController>();
    final lines = waiter.order;
    final total = waiter.total == 0 ? 1960.40 : waiter.total;
    if (_completed) {
      return Center(
        child: AppCard(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 68,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  'Cuenta dividida correctamente',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Las partes están listas para continuar con el cobro.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.go('/app/restaurant/waiter'),
                  icon: const Icon(Icons.table_restaurant),
                  label: const Text('Volver a mesas'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(
                      '/app/restaurant/waiter/tables/${widget.tableId}',
                    ),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Dividir cuenta · Mesa ${widget.tableId.split('-').last}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(total),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SegmentedButton<_SplitMode>(
                segments: const [
                  ButtonSegment(
                    value: _SplitMode.equal,
                    icon: Icon(Icons.groups_outlined),
                    label: Text('Partes iguales'),
                  ),
                  ButtonSegment(
                    value: _SplitMode.products,
                    icon: Icon(Icons.receipt_long_outlined),
                    label: Text('Por productos'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (value) =>
                    setState(() => _mode = value.first),
              ),
              const SizedBox(height: 18),
              if (_mode == _SplitMode.equal)
                _EqualSplitPanel(
                  people: _people,
                  total: total,
                  onChanged: (value) => setState(() => _people = value),
                )
              else
                _ProductSplitPanel(
                  lines: lines,
                  assignments: _assignments,
                  fallbackTotal: total,
                  onAssigned: (id, part) =>
                      setState(() => _assignments[id] = part),
                ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _canComplete(lines)
                      ? () => setState(() => _completed = true)
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar división'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canComplete(List<WaiterOrderLine> lines) {
    if (_mode == _SplitMode.equal) return _people >= 2 && _people <= 12;
    if (lines.isEmpty) return _assignments.length >= 3;
    return lines.every((line) => _assignments.containsKey(line.product.id));
  }
}

class _EqualSplitPanel extends StatelessWidget {
  const _EqualSplitPanel({
    required this.people,
    required this.total,
    required this.onChanged,
  });

  final int people;
  final double total;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        const Text(
          '¿Entre cuántas personas se divide?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: people > 2 ? () => onChanged(people - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 90,
              child: Text(
                '$people',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            IconButton.filled(
              onPressed: people < 12 ? () => onChanged(people + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          AppFormatters.currency(total / people),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.tenantAccent,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text('por persona, impuestos incluidos'),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < people; i++)
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.tenantAccent.withValues(alpha: 0.12),
                child: Text('${i + 1}'),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ProductSplitPanel extends StatelessWidget {
  const _ProductSplitPanel({
    required this.lines,
    required this.assignments,
    required this.fallbackTotal,
    required this.onAssigned,
  });

  final List<WaiterOrderLine> lines;
  final Map<String, int> assignments;
  final double fallbackTotal;
  final void Function(String, int) onAssigned;

  @override
  Widget build(BuildContext context) {
    final displayLines = lines.isEmpty
        ? const [
            ('demo-1', 'Filete de res × 2', 690.0),
            ('demo-2', 'Carpaccio de atún', 195.0),
            ('demo-3', 'Bebidas y postres', 805.0),
          ]
        : [
            for (final line in lines)
              (
                line.product.id,
                '${line.product.name} × ${line.quantity}',
                line.product.price * line.quantity,
              ),
          ];
    final unassigned = displayLines
        .where((line) => !assignments.containsKey(line.$1))
        .length;
    final partA = displayLines
        .where((line) => assignments[line.$1] == 0)
        .fold<double>(0, (sum, line) => sum + line.$3);
    final partB = displayLines
        .where((line) => assignments[line.$1] == 1)
        .fold<double>(0, (sum, line) => sum + line.$3);
    return Column(
      children: [
        if (unassigned > 0)
          AppCard(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning),
                const SizedBox(width: 10),
                Text('$unassigned productos aún no tienen cuenta asignada.'),
              ],
            ),
          ),
        if (unassigned > 0) const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              for (final line in displayLines)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(line.$2),
                  subtitle: Text(AppFormatters.currency(line.$3)),
                  trailing: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('A')),
                      ButtonSegment(value: 1, label: Text('B')),
                    ],
                    emptySelectionAllowed: true,
                    selected: assignments.containsKey(line.$1)
                        ? {assignments[line.$1]!}
                        : const {},
                    onSelectionChanged: (value) {
                      if (value.isNotEmpty) onAssigned(line.$1, value.first);
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BillPart(
                label: 'Cuenta A',
                subtotal: partA,
                fallback: fallbackTotal / 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BillPart(
                label: 'Cuenta B',
                subtotal: partB,
                fallback: fallbackTotal / 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BillPart extends StatelessWidget {
  const _BillPart({
    required this.label,
    required this.subtotal,
    required this.fallback,
  });

  final String label;
  final double subtotal;
  final double fallback;

  @override
  Widget build(BuildContext context) {
    final base = subtotal == 0 ? fallback / 1.16 : subtotal;
    final tax = base * 0.16;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text('Subtotal: ${AppFormatters.currency(base)}'),
          Text('IVA 16%: ${AppFormatters.currency(tax)}'),
          const Divider(),
          Text(
            'Total: ${AppFormatters.currency(base + tax)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
