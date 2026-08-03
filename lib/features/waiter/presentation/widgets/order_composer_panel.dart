import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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
              Text(
                'Nueva comanda',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text('${controller.order.length} partidas'),
            ],
          ),
        ),
        const Divider(height: 1),
        if (controller.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.destructive.withValues(alpha: 0.08),
            child: Text(
              controller.errorMessage!,
              style: const TextStyle(color: AppColors.destructive),
            ),
          ),
        Expanded(
          child: controller.order.isEmpty
              ? const OperationalEmptyState(
                  title: 'Comanda vacía',
                  message: 'Agrega productos disponibles del menú real.',
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
                        Text(
                          '${line.product.availableStock} disponibles',
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Quitar una unidad',
                              onPressed: controller.saving
                                  ? null
                                  : () => controller.changeQuantity(
                                      line.product,
                                      -1,
                                    ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${line.quantity}'),
                            IconButton(
                              tooltip: 'Agregar una unidad',
                              onPressed: controller.saving
                                  ? null
                                  : () => controller.changeQuantity(
                                      line.product,
                                      1,
                                    ),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            Text(
                              AppFormatters.currency(line.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        TextFormField(
                          key: ValueKey(line.product.id),
                          initialValue: line.notes,
                          maxLength: 300,
                          onChanged: (value) =>
                              controller.setLineNotes(line.product, value),
                          decoration: const InputDecoration(
                            labelText: 'Notas del producto',
                            hintText: 'Ej. sin cebolla, término medio',
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
              TextFormField(
                initialValue: controller.specialNotes,
                onChanged: controller.setSpecialNotes,
                maxLines: 2,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Notas generales',
                  hintText: 'Alergias, prioridad u observaciones',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Total de partidas'),
                  const Spacer(),
                  Text(
                    AppFormatters.currency(controller.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: controller.order.isEmpty || controller.saving
                      ? null
                      : () async {
                          final order = await controller.createAndSendOrder(
                            tableId,
                          );
                          if (order == null || !context.mounted) return;
                          AppSuccessFeedback.show(
                            context,
                            'Comanda ${order.folio} enviada a cocina.',
                          );
                          context.go(
                            '/app/restaurant/waiter/orders/${order.id}',
                          );
                        },
                  icon: controller.saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Crear y enviar a cocina'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
