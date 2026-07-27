import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';

class HomeSelectorPage extends StatelessWidget {
  const HomeSelectorPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              children: [
                const Icon(Icons.bolt, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Impulsa Suite',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona el flujo que quieres explorar.',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 36),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _FlowCard(
                        title: 'Superadmin',
                        description:
                            'Gestión global de tenants y salud de plataforma.',
                        icon: Icons.admin_panel_settings_outlined,
                        color: AppColors.superadminSidebar,
                        onTap: () => context.go('/superadmin/login'),
                      ),
                      _FlowCard(
                        title: 'Tenant workspace',
                        description:
                            'Administración, POS, finanzas y restaurante.',
                        icon: Icons.storefront_outlined,
                        color: AppColors.tenantAccent,
                        onTap: () => context.go('/tenant-login'),
                      ),
                    ];
                    if (constraints.maxWidth < 760) {
                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 16),
                          cards[1],
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 18),
                          Expanded(child: cards[1]),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 22),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Abrir flujo',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 7),
            Icon(Icons.arrow_forward, color: color, size: 18),
          ],
        ),
      ],
    ),
  );
}
