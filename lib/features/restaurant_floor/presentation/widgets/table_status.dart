import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../data/models/restaurant_models.dart';

Color tableStatusColor(RestaurantTableStatus status) => switch (status) {
  RestaurantTableStatus.available => AppColors.success,
  RestaurantTableStatus.occupied => AppColors.tenantAccent,
  RestaurantTableStatus.reserved => const Color(0xFF4F46E5),
  RestaurantTableStatus.dirty => AppColors.mutedForeground,
};

String tableStatusLabel(RestaurantTableStatus status) => switch (status) {
  RestaurantTableStatus.available => 'Disponible',
  RestaurantTableStatus.occupied => 'Ocupada',
  RestaurantTableStatus.reserved => 'Reservada',
  RestaurantTableStatus.dirty => 'Por limpiar',
};

String kitchenOrderStatusLabel(KitchenOrderStatus status) => switch (status) {
  KitchenOrderStatus.pending => 'Pendiente',
  KitchenOrderStatus.inPreparation => 'En preparación',
  KitchenOrderStatus.ready => 'Lista',
  KitchenOrderStatus.delivered => 'Entregada',
  KitchenOrderStatus.cancelled => 'Cancelada',
};

Color kitchenOrderStatusColor(KitchenOrderStatus status) => switch (status) {
  KitchenOrderStatus.pending => AppColors.primary,
  KitchenOrderStatus.inPreparation => AppColors.warning,
  KitchenOrderStatus.ready => AppColors.success,
  KitchenOrderStatus.delivered => AppColors.mutedForeground,
  KitchenOrderStatus.cancelled => AppColors.destructive,
};

String kitchenItemStatusLabel(KitchenItemStatus status) => switch (status) {
  KitchenItemStatus.pending => 'Pendiente',
  KitchenItemStatus.inPreparation => 'Preparando',
  KitchenItemStatus.ready => 'Listo',
  KitchenItemStatus.delivered => 'Entregado',
  KitchenItemStatus.cancelled => 'Cancelado',
};

class TableStatusBadge extends StatelessWidget {
  const TableStatusBadge({super.key, required this.status});

  final RestaurantTableStatus status;

  @override
  Widget build(BuildContext context) => AppBadge(
    label: tableStatusLabel(status),
    color: tableStatusColor(status),
  );
}

class KitchenOrderStatusBadge extends StatelessWidget {
  const KitchenOrderStatusBadge({super.key, required this.status});

  final KitchenOrderStatus status;

  @override
  Widget build(BuildContext context) => AppBadge(
    label: kitchenOrderStatusLabel(status),
    color: kitchenOrderStatusColor(status),
  );
}
