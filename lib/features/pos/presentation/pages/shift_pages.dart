import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../controllers/pos_controller.dart';

class OpenShiftPage extends StatefulWidget {
  const OpenShiftPage({super.key});

  @override
  State<OpenShiftPage> createState() => _OpenShiftPageState();
}

class _OpenShiftPageState extends State<OpenShiftPage> {
  final _cash = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final pos = context.read<PosController>();
    if (pos.status == PosStatus.idle) pos.load();
  }

  @override
  void dispose() {
    _cash.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosController>();
    if (pos.loading) {
      return const AppLoadingState(message: 'Consultando turno activo…');
    }
    if (pos.shiftOpen) {
      return OperationalEmptyState(
        title: 'Ya tienes un turno abierto',
        message:
            'El turno inició ${_dateTime(pos.activeShift?.openedAt)} y está '
            'listo para registrar ventas.',
        actionLabel: 'Ir al POS',
        onAction: () => context.go('/app/pos'),
      );
    }
    final openingAmount = double.tryParse(_cash.text);
    return _ShiftScaffold(
      title: 'Abrir turno de caja',
      subtitle:
          'El turno se abrirá en la sucursal activa de tu sesión. No se envía '
          'branchId en el body.',
      errorMessage: pos.errorMessage,
      children: [
        TextField(
          controller: _cash,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Fondo inicial (MXN)',
            prefixText: r'$ ',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notes,
          maxLength: 500,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notas de apertura (opcional)',
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                pos.savingShift || openingAmount == null || openingAmount < 0
                ? null
                : () async {
                    final success = await pos.openShift(
                      openingAmount: openingAmount,
                      notes: _notes.text,
                    );
                    if (!context.mounted || !success) return;
                    AppSuccessFeedback.show(
                      context,
                      'Turno abierto correctamente.',
                    );
                    context.go('/app/pos');
                  },
            icon: pos.savingShift
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_open),
            label: Text(pos.savingShift ? 'Abriendo…' : 'Abrir turno'),
          ),
        ),
      ],
    );
  }
}

class CloseShiftPage extends StatefulWidget {
  const CloseShiftPage({super.key});

  @override
  State<CloseShiftPage> createState() => _CloseShiftPageState();
}

class _CloseShiftPageState extends State<CloseShiftPage> {
  final _counted = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pos = context.read<PosController>();
      if (pos.status == PosStatus.idle) await pos.load();
      if (mounted) await pos.loadActiveSummary();
    });
  }

  @override
  void dispose() {
    _counted.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosController>();
    if (pos.loading || pos.loadingSummary) {
      return const AppLoadingState(message: 'Calculando corte de caja…');
    }
    final shift = pos.activeShift;
    if (shift == null) {
      return OperationalEmptyState(
        title: 'No hay turno activo',
        message: 'Abre un turno antes de solicitar el cierre de caja.',
        actionLabel: 'Abrir turno',
        onAction: () => context.go('/app/pos/shifts/open'),
      );
    }

    final summary = pos.activeSummary;
    final expected = summary?.totalCash ?? shift.totalCash;
    final counted = double.tryParse(_counted.text);
    final difference = (counted ?? 0) - expected;
    return _ShiftScaffold(
      title: 'Cierre de turno',
      subtitle:
          'Turno iniciado ${_dateTime(shift.openedAt)}. El backend impedirá '
          'el cierre si existe un pago PENDING.',
      errorMessage: pos.errorMessage,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: [
            _ShiftMetric(
              'Ventas totales',
              AppFormatters.currency(summary?.totalSales ?? shift.totalSales),
            ),
            _ShiftMetric(
              'Tickets',
              '${summary?.salesCount ?? shift.salesCount}',
            ),
            _ShiftMetric('Efectivo vendido', AppFormatters.currency(expected)),
            _ShiftMetric(
              'Tarjeta confirmada',
              AppFormatters.currency(summary?.totalCard ?? shift.totalCard),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _counted,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Conteo físico de efectivo',
            prefixText: r'$ ',
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          tileColor: counted != null && difference.abs() < 0.01
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.warning.withValues(alpha: 0.1),
          title: const Text('Efectivo vendido esperado'),
          subtitle: Text(AppFormatters.currency(expected)),
          trailing: Text(
            'Diferencia ${AppFormatters.currency(difference)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _notes,
          maxLength: 500,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notas de cierre (opcional)',
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: counted == null || counted < 0 || pos.savingShift
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Confirmar cierre'),
                        content: Text(
                          'Se enviará un conteo de '
                          '${AppFormatters.currency(counted)}. '
                          'Diferencia: '
                          '${AppFormatters.currency(difference)}.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Cerrar turno'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    final success = await pos.closeActiveShift(
                      closingAmount: counted,
                      notes: _notes.text,
                    );
                    if (!context.mounted || !success) return;
                    AppSuccessFeedback.show(context, 'Turno cerrado.');
                    context.go('/app/dashboard');
                  },
            icon: pos.savingShift
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(pos.savingShift ? 'Cerrando…' : 'Confirmar cierre'),
          ),
        ),
        if (pos.canManageShifts && pos.shiftHistory.isNotEmpty) ...[
          const Divider(height: 42),
          Text(
            'Turnos recientes de la sucursal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final item in pos.shiftHistory.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item.isOpen ? Icons.lock_open : Icons.lock_outline,
                color: item.isOpen ? AppColors.warning : AppColors.success,
              ),
              title: Text(_dateTime(item.openedAt)),
              subtitle: Text(
                '${item.salesCount} ventas · Cajero '
                '${_shortId(item.cashierId)}',
              ),
              trailing: Text(AppFormatters.currency(item.totalSales)),
            ),
        ],
      ],
    );
  }
}

class _ShiftScaffold extends StatelessWidget {
  const _ShiftScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.errorMessage,
  });

  final String title;
  final String subtitle;
  final String? errorMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.destructive),
                  ),
                ],
                const Divider(height: 32),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ShiftMetric extends StatelessWidget {
  const _ShiftMetric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.background,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    ),
  );
}

String _dateTime(DateTime? value) {
  if (value == null) return 'sin fecha';
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${AppFormatters.date(value)} · $hour:$minute';
}

String _shortId(String value) =>
    value.length <= 8 ? value : '${value.substring(0, 8)}…';
