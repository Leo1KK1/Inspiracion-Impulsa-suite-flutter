import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../data/models/purchasing_models.dart';

class PurchaseOrderStatusBadge extends StatelessWidget {
  const PurchaseOrderStatusBadge({super.key, required this.status});
  final PurchaseOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PurchaseOrderStatus.draft => ('BORRADOR', AppColors.mutedForeground),
      PurchaseOrderStatus.submitted => ('ENVIADA', const Color(0xFF7C3AED)),
      PurchaseOrderStatus.partiallyReceived => (
        'RECIBIDA PARCIAL',
        AppColors.warning,
      ),
      PurchaseOrderStatus.received => ('RECIBIDA', AppColors.success),
      PurchaseOrderStatus.cancelled => ('CANCELADA', AppColors.destructive),
    };
    return AppBadge(label: label, color: color);
  }
}
