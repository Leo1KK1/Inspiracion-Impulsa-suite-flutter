import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../data/models/finance_models.dart';

class ExpenseStatusBadge extends StatelessWidget {
  const ExpenseStatusBadge({super.key, required this.status});
  final ExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ExpenseStatus.approved => ('APROBADO', AppColors.success),
      ExpenseStatus.pending => ('PENDIENTE', AppColors.warning),
      ExpenseStatus.rejected => ('RECHAZADO', AppColors.destructive),
      ExpenseStatus.cancelled => ('CANCELADO', AppColors.mutedForeground),
    };
    return AppBadge(label: label, color: color);
  }
}
