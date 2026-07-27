import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../widgets/app_badges.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';

class ReferenceStatePage extends StatelessWidget {
  const ReferenceStatePage({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(title: title, subtitle: description),
        const SizedBox(height: 20),
        const AppCard(
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'La referencia React conserva esta ruta como estado informativo, sin datos ni acciones de negocio. Flutter mantiene el mismo alcance.',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DesignSystemPage extends StatelessWidget {
  const DesignSystemPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Sistema de diseño',
                subtitle: 'Tokens y componentes compartidos de Impulsa Suite.',
              ),
              const SizedBox(height: 20),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ColorSwatch('Primary', AppColors.primary),
                  _ColorSwatch('Tenant accent', AppColors.tenantAccent),
                  _ColorSwatch('Success', AppColors.success),
                  _ColorSwatch('Warning', AppColors.warning),
                  _ColorSwatch('Destructive', AppColors.destructive),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Componentes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppBadge(label: 'ACTIVO', color: AppColors.success),
                        AppBadge(label: 'BAJO STOCK', color: AppColors.warning),
                        AppBadge(
                          label: 'RESTRINGIDO',
                          color: AppColors.destructive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      children: [
                        FilledButton(
                          onPressed: null,
                          child: Text('Acción primaria'),
                        ),
                        OutlinedButton(
                          onPressed: null,
                          child: Text('Acción secundaria'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    height: 86,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadii.lg),
    ),
    alignment: Alignment.bottomLeft,
    child: Text(
      label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  );
}
