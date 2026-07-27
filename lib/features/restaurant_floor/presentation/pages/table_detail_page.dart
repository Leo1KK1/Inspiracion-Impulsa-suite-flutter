import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../controllers/restaurant_controller.dart';
import '../widgets/table_status.dart';

class TableDetailPage extends StatelessWidget {
  const TableDetailPage({super.key, required this.tableId});
  final String tableId;

  @override
  Widget build(BuildContext context) {
    final restaurant = context.watch<RestaurantController>();
    if (restaurant.tables.isEmpty) {
      Future.microtask(restaurant.load);
      return const AppLoadingState(message: 'Cargando mesa…');
    }
    final table = restaurant.tables
        .where((item) => item.id == tableId)
        .firstOrNull;
    if (table == null) {
      return OperationalEmptyState(
        title: 'Mesa no encontrada',
        message: 'La mesa solicitada no existe.',
        actionLabel: 'Volver al plano',
        onAction: () => context.go('/app/restaurant/floor'),
      );
    }
    const items = [
      ('Filete a la plancha', 'Caliente', 2, 285.0, 'En preparación'),
      ('Ensalada de la casa', 'Fría', 2, 125.0, 'Lista'),
      ('Limonada mineral', 'Bebidas', 4, 68.0, 'Entregada'),
      ('Postre del día', 'Fría', 2, 95.0, 'Pendiente'),
    ];
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.$3 * item.$4,
    );
    final tax = subtotal * 0.16;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Mesa ${table.number}',
            subtitle:
                '${zoneLabel(table.zone)} · ${table.waiterName ?? 'Sin mesero'}',
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/app/restaurant/floor'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Plano'),
              ),
              TableStatusBadge(status: table.status),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width < 780 ? 1 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.15,
            children: [
              MetricCard(
                label: 'Comensales',
                value: '${table.guestCount}',
                icon: Icons.groups_outlined,
              ),
              MetricCard(
                label: 'Tiempo',
                value: '${table.openedMinutes ?? 0} min',
                icon: Icons.schedule,
              ),
              MetricCard(
                label: 'Cuenta actual',
                value: AppFormatters.currency(subtotal + tax),
                icon: Icons.receipt_long,
              ),
              MetricCard(
                label: 'Promedio / persona',
                value: AppFormatters.currency(
                  (subtotal + tax) /
                      (table.guestCount == 0 ? 1 : table.guestCount),
                ),
                icon: Icons.person_outline,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            color: AppColors.warning.withValues(alpha: 0.07),
            child: const ListTile(
              leading: Icon(
                Icons.sticky_note_2_outlined,
                color: AppColors.warning,
              ),
              title: Text('Notas especiales'),
              subtitle: Text(
                'Una persona con alergia a nueces. Filete sin guarnición.',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Platillo')),
                  DataColumn(label: Text('Estación')),
                  DataColumn(label: Text('Cantidad'), numeric: true),
                  DataColumn(label: Text('Precio'), numeric: true),
                  DataColumn(label: Text('Estado')),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      cells: [
                        DataCell(Text(item.$1)),
                        DataCell(Text(item.$2)),
                        DataCell(Text('${item.$3}')),
                        DataCell(Text(AppFormatters.currency(item.$4))),
                        DataCell(Text(item.$5)),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _Total('Subtotal', subtotal),
                  _Total('IVA 16%', tax),
                  const Divider(),
                  _Total('Total', subtotal + tax, strong: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          fontSize: strong ? 20 : 14,
        ),
      ),
    ],
  );
}
