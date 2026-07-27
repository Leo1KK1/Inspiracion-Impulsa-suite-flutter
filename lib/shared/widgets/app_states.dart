import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'app_card.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message = 'Cargando información…'});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: AppCard(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Text(message),
        ],
      ),
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _MessageState(
    icon: Icons.error_outline,
    color: AppColors.destructive,
    title: 'Algo salió mal',
    message: message,
    actionLabel: 'Reintentar',
    onAction: onRetry,
  );
}

class OperationalEmptyState extends StatelessWidget {
  const OperationalEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _MessageState(
    icon: Icons.inbox_outlined,
    color: AppColors.mutedForeground,
    title: title,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

class BranchContextRequiredState extends StatelessWidget {
  const BranchContextRequiredState({super.key});

  @override
  Widget build(BuildContext context) => _MessageState(
    icon: Icons.account_tree_outlined,
    color: AppColors.warning,
    title: 'Selecciona una sucursal',
    message: 'Esta operación necesita una sucursal activa.',
    actionLabel: 'Elegir sucursal',
    onAction: () => context.go('/app/branch-context'),
  );
}

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key, this.requiredRoles = const []});
  final List<String> requiredRoles;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: _MessageState(
      icon: Icons.lock_outline,
      color: AppColors.destructive,
      title: 'Acceso restringido',
      message: requiredRoles.isEmpty
          ? 'Tu sesión no tiene permiso para ver este contenido.'
          : 'Se requiere alguno de estos roles: ${requiredRoles.join(', ')}.',
      actionLabel: 'Volver al inicio',
      onAction: () => context.go('/app/dashboard'),
    ),
  );
}

class TenantSuspendedState extends StatelessWidget {
  const TenantSuspendedState({super.key});

  @override
  Widget build(BuildContext context) => const _MessageState(
    icon: Icons.business_outlined,
    color: AppColors.warning,
    title: 'Workspace suspendido',
    message: 'Contacta al administrador de la plataforma para continuar.',
  );
}

class AppSuccessFeedback {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: AppCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ),
  );
}
