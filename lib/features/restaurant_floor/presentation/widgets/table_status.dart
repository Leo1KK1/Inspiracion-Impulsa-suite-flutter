import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../data/models/restaurant_models.dart';

Color tableStatusColor(RestaurantTableStatus status) => switch (status) {
  RestaurantTableStatus.available => AppColors.success,
  RestaurantTableStatus.occupied => AppColors.tenantAccent,
  RestaurantTableStatus.waitingOrder => const Color(0xFFD97706),
  RestaurantTableStatus.inPreparation => const Color(0xFFEA580C),
  RestaurantTableStatus.readyToBill => const Color(0xFF9333EA),
  RestaurantTableStatus.dirty => AppColors.mutedForeground,
  RestaurantTableStatus.reserved => const Color(0xFF4F46E5),
};

String tableStatusLabel(RestaurantTableStatus status) => switch (status) {
  RestaurantTableStatus.available => 'Disponible',
  RestaurantTableStatus.occupied => 'Ocupada',
  RestaurantTableStatus.waitingOrder => 'Esperando orden',
  RestaurantTableStatus.inPreparation => 'En preparación',
  RestaurantTableStatus.readyToBill => 'Lista para cobrar',
  RestaurantTableStatus.dirty => 'Sucia',
  RestaurantTableStatus.reserved => 'Reservada',
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

String zoneLabel(RestaurantZone zone) => switch (zone) {
  RestaurantZone.salon => 'Salón',
  RestaurantZone.terraza => 'Terraza',
  RestaurantZone.barra => 'Barra',
  RestaurantZone.privado => 'Privado',
};
