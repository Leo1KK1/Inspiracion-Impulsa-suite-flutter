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
  bool _processing = false;

  @override
  void dispose() {
    _receivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosController>();
    if (pos.cart.isEmpty) {
      return OperationalEmptyState(
        title: 'No hay una venta por cobrar',
        message: 'Agrega productos antes de abrir el checkout.',
        actionLabel: 'Volver al POS',
        onAction: () => context.go('/app/pos'),
      );
    }
    final received = double.tryParse(_receivedController.text) ?? 0;
    final change = received - pos.total;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
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
                    'Cobrar venta',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final summary = _OrderSummary(pos: pos);
                  final payment = _PaymentPanel(
                    method: _method,
                    onMethodChanged: (value) => setState(() => _method = value),
                    receivedController: _receivedController,
                    change: change,
                    onAmountChanged: () => setState(() {}),
                  );
                  if (constraints.maxWidth < 720) {
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      _processing ||
                          (_method == PaymentMethod.cash &&
                              received < pos.total)
                      ? null
                      : () => _complete(context, pos),
                  icon: _processing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _processing
                        ? 'Procesando…'
                        : 'Confirmar pago de ${AppFormatters.currency(pos.total)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete(BuildContext context, PosController pos) async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    pos.completeSale(_method);
    if (!context.mounted) return;
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
        content: const Text(
          'El pago se registró y el inventario fue actualizado.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/app/pos/tickets');
            },
            child: const Text('Ver tickets'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go('/app/pos');
            },
            child: const Text('Nueva venta'),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.pos});
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
              subtitle: Text('${line.quantity} × ${line.product.price}'),
              trailing: Text(
                AppFormatters.currency(line.product.price * line.quantity),
              ),
            ),
          const Divider(),
          _Row('Subtotal', pos.subtotal),
          _Row('IVA 16%', pos.tax),
          _Row('Total', pos.total, strong: true),
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
    required this.change,
    required this.onAmountChanged,
  });

  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final TextEditingController receivedController;
  final double change;
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
                value: PaymentMethod.transfer,
                icon: Icon(Icons.swap_horiz),
                label: Text('Transferencia'),
              ),
            ],
            selected: {method},
            onSelectionChanged: (selection) => onMethodChanged(selection.first),
          ),
          if (method == PaymentMethod.cash) ...[
            const SizedBox(height: 18),
            TextField(
              controller: receivedController,
              onChanged: (_) => onAmountChanged(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Efectivo recibido',
                prefixText: r'$ ',
              ),
            ),
            const SizedBox(height: 12),
            _Row('Cambio', change > 0 ? change : 0, strong: true),
          ] else ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.contactless, size: 48),
                  SizedBox(height: 8),
                  Text('Terminal lista para procesar el pago.'),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.strong = false});
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
