import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TenantSessionController>().session;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Mi perfil',
            subtitle: 'Datos de identidad, sesión y acceso al workspace.',
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.tenantAccent,
                      child: Text(
                        session?.userName
                                .split(' ')
                                .take(2)
                                .map((part) => part[0])
                                .join() ??
                            'ML',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      session?.userName ?? 'María López',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      session?.userEmail ?? '',
                      style: const TextStyle(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final role in session?.roleCodes ?? const [])
                          RoleBadge(role: role),
                      ],
                    ),
                    const Divider(height: 34),
                    _InfoRow('Tenant', session?.tenantName ?? ''),
                    _InfoRow(
                      'Sucursal activa',
                      session?.activeBranchName ?? 'Sin seleccionar',
                    ),
                    _InfoRow('Actor', session?.actorType ?? ''),
                    _InfoRow('Sesión', session?.sessionId ?? ''),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
