import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../restaurant_floor/data/models/restaurant_models.dart';
import '../../data/models/waiter_models.dart';
import '../controllers/waiter_controller.dart';

class SplitBillPage extends StatefulWidget {
  const SplitBillPage({super.key, required this.tableId});

  final String tableId;

  @override
  State<SplitBillPage> createState() => _SplitBillPageState();
}

class _SplitBillPageState extends State<SplitBillPage> {
  SplitBillMode _mode = SplitBillMode.equal;
  int _people = 2;
  final Map<String, int> _assignments = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WaiterController>().loadTable(widget.tableId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterController>();
    if (waiter.loadingTable && waiter.activeTable == null) {
      return const AppLoadingState(message: 'Cargando cuenta real…');
    }
    final table = waiter.activeTable;
    if (table == null || table.activeSession == null) {
      return AppErrorState(
        message: waiter.errorMessage ?? 'La mesa no tiene una sesión abierta.',
        onRetry: () => waiter.loadTable(widget.tableId),
      );
    }
    final items = [
      for (final order in waiter.tableOrders)
        if (order.status != KitchenOrderStatus.cancelled)
          for (final item in order.items)
            if (item.status != KitchenItemStatus.cancelled)
              (order: order, item: item),
    ];
    final total = items.fold<double>(0, (sum, row) => sum + row.item.lineTotal);
    return RefreshIndicator(
      onRefresh: () => waiter.loadTable(widget.tableId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      tooltip: 'Volver a la mesa',
                      onPressed: () => context.go(
                        '/app/restaurant/waiter/tables/${widget.tableId}',
                      ),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        'Dividir cuenta · ${table.name}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      AppFormatters.currency(total),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                if (waiter.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    color: AppColors.destructive.withValues(alpha: 0.08),
                    child: Text(
                      waiter.errorMessage!,
                      style: const TextStyle(color: AppColors.destructive),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SegmentedButton<SplitBillMode>(
                  segments: const [
                    ButtonSegment(
                      value: SplitBillMode.equal,
                      icon: Icon(Icons.groups_outlined),
                      label: Text('Partes iguales'),
                    ),
                    ButtonSegment(
                      value: SplitBillMode.byItem,
                      icon: Icon(Icons.receipt_long_outlined),
                      label: Text('Por partidas'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: waiter.saving
                      ? null
                      : (value) {
                          setState(() => _mode = value.first);
                          waiter.clearSplitResult();
                        },
                ),
                const SizedBox(height: 18),
                if (items.isEmpty)
                  const OperationalEmptyState(
                    title: 'Cuenta vacía',
                    message: 'No hay partidas activas para dividir.',
                  )
                else if (_mode == SplitBillMode.equal)
                  _EqualSplitPanel(
                    people: _people,
                    total: total,
                    onChanged: (value) {
                      setState(() => _people = value);
                      waiter.clearSplitResult();
                    },
                  )
                else
                  _ProductSplitPanel(
                    items: items,
                    assignments: _assignments,
                    onAssigned: (id, part) {
                      setState(() => _assignments[id] = part);
                      waiter.clearSplitResult();
                    },
                  ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed:
                        items.isEmpty || waiter.saving || !_canSubmit(items)
                        ? null
                        : () => _submit(waiter, items),
                    icon: waiter.saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.calculate_outlined),
                    label: const Text('Calcular división'),
                  ),
                ),
                if (waiter.splitResult case final result?) ...[
                  const SizedBox(height: 18),
                  _SplitResultCard(result: result),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit(List<({KitchenOrder order, KitchenOrderItem item})> items) {
    if (_mode == SplitBillMode.equal) return _people >= 1 && _people <= 30;
    return items.every((row) => _assignments.containsKey(row.item.id)) &&
        _assignments.containsValue(0) &&
        _assignments.containsValue(1);
  }

  Future<void> _submit(
    WaiterController waiter,
    List<({KitchenOrder order, KitchenOrderItem item})> items,
  ) async {
    final success = _mode == SplitBillMode.equal
        ? await waiter.splitEqual(widget.tableId, _people)
        : await waiter.splitByItem(widget.tableId, [
            SplitBillAssignment(
              guestLabel: 'Cuenta A',
              itemIds: [
                for (final row in items)
                  if (_assignments[row.item.id] == 0) row.item.id,
              ],
            ),
            SplitBillAssignment(
              guestLabel: 'Cuenta B',
              itemIds: [
                for (final row in items)
                  if (_assignments[row.item.id] == 1) row.item.id,
              ],
            ),
          ]);
    if (success && mounted) {
      AppSuccessFeedback.show(context, 'División calculada por el backend.');
    }
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
              tooltip: 'Reducir partes',
              onPressed: people > 1 ? () => onChanged(people - 1) : null,
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
              tooltip: 'Aumentar partes',
              onPressed: people < 30 ? () => onChanged(people + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Vista previa: ${AppFormatters.currency(total / people)} por parte',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'El backend ajustará los centavos restantes en la última parte.',
        ),
      ],
    ),
  );
}

class _ProductSplitPanel extends StatelessWidget {
  const _ProductSplitPanel({
    required this.items,
    required this.assignments,
    required this.onAssigned,
  });

  final List<({KitchenOrder order, KitchenOrderItem item})> items;
  final Map<String, int> assignments;
  final void Function(String, int) onAssigned;

  @override
  Widget build(BuildContext context) {
    final unassigned = items
        .where((row) => !assignments.containsKey(row.item.id))
        .length;
    return Column(
      children: [
        if (unassigned > 0) ...[
          AppCard(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('$unassigned partidas aún no tienen cuenta.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          child: Column(
            children: [
              for (final row in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${row.item.quantity} × ${row.item.productName}'),
                  subtitle: Text(
                    '${row.order.folio} · '
                    '${AppFormatters.currency(row.item.lineTotal)}',
                  ),
                  trailing: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('A')),
                      ButtonSegment(value: 1, label: Text('B')),
                    ],
                    emptySelectionAllowed: true,
                    selected: assignments.containsKey(row.item.id)
                        ? {assignments[row.item.id]!}
                        : const {},
                    onSelectionChanged: (value) {
                      if (value.isNotEmpty) {
                        onAssigned(row.item.id, value.first);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplitResultCard extends StatelessWidget {
  const _SplitResultCard({required this.result});

  final SplitBillResult result;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.success.withValues(alpha: 0.06),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Resultado del backend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Total: ${AppFormatters.currency(result.grandTotal)}'),
        for (final part in result.parts)
          Text('Parte ${part.part}: ${AppFormatters.currency(part.amount)}'),
        for (final group in result.groups)
          Text('${group.guestLabel}: ${AppFormatters.currency(group.amount)}'),
        if (result.unassignedItems.isNotEmpty)
          Text(
            '${result.unassignedItems.length} partidas quedaron sin asignar.',
            style: const TextStyle(color: AppColors.warning),
          ),
      ],
    ),
  );
}
