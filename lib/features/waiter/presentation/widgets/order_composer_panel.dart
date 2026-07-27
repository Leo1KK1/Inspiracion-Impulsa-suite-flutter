import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../controllers/waiter_controller.dart';

class OrderComposerPanel extends StatelessWidget {
  const OrderComposerPanel({
    super.key,
    required this.controller,
    required this.tableId,
  });

  final WaiterController controller;
  final String tableId;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Comanda', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${controller.order.length} partidas'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: controller.order.isEmpty
              ? const OperationalEmptyState(
                  title: 'Comanda vacía',
                  message: 'Agrega productos del menú.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: controller.order.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final line = controller.order[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  controller.changeQuantity(line.product, -1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${line.quantity}'),
                            IconButton(
                              onPressed: () =>
                                  controller.changeQuantity(line.product, 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            Text(
                              AppFormatters.currency(
                                line.product.price * line.quantity,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          onChanged: (value) =>
                              controller.setLineNotes(line.product, value),
                          decoration: const InputDecoration(
                            hintText: 'Notas del producto…',
                            isDense: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => controller.specialNotes = value,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Alergias o notas especiales…',
                ),
              ),
              const SizedBox(height: 12),
              _Total('Subtotal', controller.subtotal),
              _Total('IVA 16%', controller.tax),
              const Divider(),
              _Total('Total', controller.total, strong: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: controller.order.isEmpty
                      ? null
                      : () {
                          controller.clearOrder();
                          AppSuccessFeedback.show(
                            context,
                            'Comanda enviada a cocina.',
                          );
                          context.go('/app/restaurant/waiter/orders/ORD-015');
                        },
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar a cocina'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.value, {this.strong = false});
  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label),
      const Spacer(),
      Text(
        AppFormatters.currency(value),
        style: TextStyle(
          fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          fontSize: strong ? 19 : 14,
        ),
      ),
    ],
  );
}
