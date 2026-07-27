import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../data/models/pos_models.dart';
import '../controllers/pos_controller.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  PaymentMethod _method = PaymentMethod.cash;
  final _receivedController = TextEditingController();
  final _notesController = TextEditingController();
  final _gatewayRefController = TextEditingController();

  @override
  void dispose() {
    _receivedController.dispose();
    _notesController.dispose();
    _gatewayRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosController>();
    final pending = pos.pendingSale;
    if (pos.cart.isEmpty && pending == null) {
      return OperationalEmptyState(
        title: 'No hay una venta por cobrar',
        message: 'Agrega productos antes de abrir el checkout.',
        actionLabel: 'Volver al POS',
        onAction: () => context.go('/app/pos'),
      );
    }

    final saleTotal = pending?.total ?? pos.total;
    final received = double.tryParse(_receivedController.text) ?? 0;
    final change = received - saleTotal;
    final isValid = switch (_method) {
      PaymentMethod.cash => received >= saleTotal,
      PaymentMethod.card => true,
      PaymentMethod.mixed => received > 0 && received < saleTotal,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/app/pos'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    pending == null ? 'Cobrar venta' : 'Pago pendiente',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              if (pos.errorMessage != null) ...[
                const SizedBox(height: 12),
                _StatusBanner(
                  color: AppColors.destructive,
                  icon: Icons.error_outline,
                  message: pos.errorMessage!,
                ),
              ],
              if (pending != null) ...[
                const SizedBox(height: 12),
                _StatusBanner(
                  color: AppColors.warning,
                  icon: Icons.schedule,
                  message:
                      'La venta ${pending.folio} ya existe en el backend. '
                      'No se creará otra; solo se reanudará su cobro pendiente.',
                ),
              ],
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final summary = pending == null
                      ? _CartSummary(pos: pos)
                      : _PendingSaleSummary(sale: pending);
                  final payment = pending == null
                      ? _PaymentPanel(
                          method: _method,
                          onMethodChanged: (value) =>
                              setState(() => _method = value),
                          receivedController: _receivedController,
                          notesController: _notesController,
                          change: change,
                          total: saleTotal,
                          onAmountChanged: () => setState(() {}),
                        )
                      : _PendingPaymentPanel(
                          pos: pos,
                          gatewayRefController: _gatewayRefController,
                          onSuccess: () => _showSuccess(pos),
                        );
                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: [summary, const SizedBox(height: 16), payment],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: 16),
                      Expanded(child: payment),
                    ],
                  );
                },
              ),
              if (pending == null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: pos.checkoutBusy || !isValid
                        ? null
                        : () => _complete(pos, received),
                    icon: pos.checkoutBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      pos.checkoutBusy
                          ? _phaseLabel(pos.checkoutPhase)
                          : 'Confirmar ${_method.label.toLowerCase()} por '
                                '${AppFormatters.currency(saleTotal)}',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete(PosController pos, double received) async {
    final success = await pos.checkout(
      _method,
      cashReceived: _method == PaymentMethod.card ? null : received,
      notes: _notesController.text,
    );
    if (!mounted || !success) return;
    await _showSuccess(pos);
  }

  Future<void> _showSuccess(PosController pos) async {
    if (!mounted) return;
    final sale = pos.lastSale;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 48,
        ),
        title: const Text('Venta completada'),
        content: Text(
          sale == null
              ? 'El backend confirmó el pago.'
              : '${sale.folio}\n'
                    'Pago confirmado por '
                    '${AppFormatters.currency(sale.total)}.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(
                sale == null
                    ? '/app/pos/tickets'
                    : '/app/pos/tickets/${sale.id}',
              );
            },
            child: const Text('Ver ticket'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              pos.resetCheckout();
              context.go('/app/pos');
            },
            child: const Text('Nueva venta'),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.pos});
  final PosController pos;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de venta',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final line in pos.cart)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.product.name),
              subtitle: Text(
                '${line.quantity} × '
                '${AppFormatters.currency(line.product.salePrice)}',
              ),
              trailing: Text(AppFormatters.currency(line.total)),
            ),
          const Divider(),
          _AmountRow('Subtotal', pos.subtotal),
          if (pos.discount > 0) _AmountRow('Descuentos', -pos.discount),
          _AmountRow('Total', pos.total, strong: true),
        ],
      ),
    ),
  );
}

class _PendingSaleSummary extends StatelessWidget {
  const _PendingSaleSummary({required this.sale});
  final PosSale sale;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sale.folio, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final item in sale.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.productName),
              subtitle: Text(
                '${item.quantity} × '
                '${AppFormatters.currency(item.unitPrice)}',
              ),
              trailing: Text(AppFormatters.currency(item.lineTotal)),
            ),
          const Divider(),
          _AmountRow('Total registrado', sale.total, strong: true),
          _AmountRow(
            'Tramo pendiente',
            sale.pendingCardPayment?.amount ?? sale.total,
          ),
        ],
      ),
    ),
  );
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({
    required this.method,
    required this.onMethodChanged,
    required this.receivedController,
    required this.notesController,
    required this.change,
    required this.total,
    required this.onAmountChanged,
  });

  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final TextEditingController receivedController;
  final TextEditingController notesController;
  final double change;
  final double total;
  final VoidCallback onAmountChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Método de pago',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment(
                value: PaymentMethod.cash,
                icon: Icon(Icons.payments_outlined),
                label: Text('Efectivo'),
              ),
              ButtonSegment(
                value: PaymentMethod.card,
                icon: Icon(Icons.credit_card),
                label: Text('Tarjeta'),
              ),
              ButtonSegment(
                value: PaymentMethod.mixed,
                icon: Icon(Icons.call_split),
                label: Text('Mixto'),
              ),
            ],
            selected: {method},
            onSelectionChanged: (selection) => onMethodChanged(selection.first),
          ),
          if (method != PaymentMethod.card) ...[
            const SizedBox(height: 18),
            TextField(
              controller: receivedController,
              onChanged: (_) => onAmountChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: method == PaymentMethod.cash
                    ? 'Efectivo recibido'
                    : 'Parte en efectivo',
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: 12),
            if (method == PaymentMethod.cash)
              _AmountRow('Cambio', change > 0 ? change : 0, strong: true)
            else
              _AmountRow(
                'Parte con tarjeta',
                (total - (double.tryParse(receivedController.text) ?? 0)).clamp(
                  0,
                  total,
                ),
                strong: true,
              ),
          ] else ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.credit_card, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'La venta se registrará como pendiente y el proveedor '
                    'activo será indicado por el backend.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: notesController,
            maxLength: 500,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas de venta (opcional)',
            ),
          ),
        ],
      ),
    ),
  );
}

class _PendingPaymentPanel extends StatelessWidget {
  const _PendingPaymentPanel({
    required this.pos,
    required this.gatewayRefController,
    required this.onSuccess,
  });

  final PosController pos;
  final TextEditingController gatewayRefController;
  final Future<void> Function() onSuccess;

  @override
  Widget build(BuildContext context) {
    final intent = pos.pendingIntent;
    final provider = intent?.gatewayProvider ?? 'POR CREAR';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmación de tarjeta',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.hub_outlined),
              title: Text(provider),
              subtitle: Text(
                intent == null
                    ? 'El intent aún no fue creado.'
                    : 'Intent ${intent.intentId}',
              ),
            ),
            if (intent == null) ...[
              const Text(
                'Reintenta la creación del intent para esta misma venta. '
                'No se registrará una venta duplicada.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: pos.checkoutBusy
                      ? null
                      : () async {
                          final success = await pos.preparePendingCardPayment();
                          if (success &&
                              pos.checkoutPhase == CheckoutPhase.success) {
                            await onSuccess();
                          }
                        },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Preparar intent'),
                ),
              ),
            ] else if (intent.isLocalDevelopment) ...[
              const _StatusBanner(
                color: AppColors.warning,
                icon: Icons.science_outlined,
                message:
                    'El backend está configurado con MOCK_LOCAL. El frontend '
                    'no simula el resultado: solicitará la confirmación al '
                    'endpoint real del backend.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: pos.checkoutBusy
                      ? null
                      : () async {
                          if (await pos.confirmPendingCard()) {
                            await onSuccess();
                          }
                        },
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Confirmar con backend'),
                ),
              ),
            ] else ...[
              _StatusBanner(
                color: AppColors.primary,
                icon: Icons.info_outline,
                message:
                    'Completa el cobro en $provider y pega la referencia real '
                    'aprobada. Impulsa consultará la pasarela antes de marcar '
                    'el pago como completado.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gatewayRefController,
                decoration: const InputDecoration(
                  labelText: 'Referencia real de la pasarela',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: pos.checkoutBusy
                      ? null
                      : () async {
                          if (await pos.confirmPendingCard(
                            gatewayRefController.text,
                          )) {
                            await onSuccess();
                          }
                        },
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Validar pago con backend'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'El contrato actual no expone clientSecret ni initPoint; por '
                'eso esta pantalla no captura PAN/CVV ni finge una aprobación.',
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ],
            if (pos.checkoutBusy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(_phaseLabel(pos.checkoutPhase)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.value, {this.strong = false});
  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          AppFormatters.currency(value),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            fontSize: strong ? 19 : 14,
          ),
        ),
      ],
    ),
  );
}

String _phaseLabel(CheckoutPhase phase) => switch (phase) {
  CheckoutPhase.validating => 'Validando venta…',
  CheckoutPhase.creatingSale => 'Registrando venta…',
  CheckoutPhase.saleCreated => 'Venta registrada…',
  CheckoutPhase.creatingCardIntent => 'Creando intent de tarjeta…',
  CheckoutPhase.awaitingGateway => 'Esperando confirmación de pasarela',
  CheckoutPhase.confirmingCard => 'Confirmando pago…',
  CheckoutPhase.success => 'Pago confirmado',
  CheckoutPhase.error => 'Revisa el error e intenta nuevamente',
  CheckoutPhase.idle => 'Listo para cobrar',
};
