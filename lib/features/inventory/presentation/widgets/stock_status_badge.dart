import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_badges.dart';

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({
    super.key,
    required this.stock,
    required this.minimum,
  });
  final int stock;
  final int minimum;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (stock) {
      0 => ('SIN STOCK', AppColors.destructive),
      _ when stock < minimum * 0.25 => ('CRÍTICO', const Color(0xFFC2410C)),
      _ when stock < minimum => ('STOCK BAJO', AppColors.warning),
      _ => ('OK', AppColors.success),
    };
    return AppBadge(label: label, color: color);
  }
}
