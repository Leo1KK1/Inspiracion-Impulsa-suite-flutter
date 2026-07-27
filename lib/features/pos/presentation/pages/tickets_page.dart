import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../data/models/pos_models.dart';
import '../controllers/pos_controller.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key, this.ticketId});
  final String? ticketId;

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant TicketsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticketId != widget.ticketId) _loadTicket();
  }

  Future<void> _load() async {
    final pos = context.read<PosController>();
    if (pos.status == PosStatus.idle) await pos.load();
    await _loadTicket();
  }

  Future<void> _loadTicket() async {
    final id = widget.ticketId;
    final pos = context.read<PosController>();
    if (id == null) {
      pos.clearSelectedTicket();
      return;
    }
    await pos.loadTicket(id);
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosController>();
    if (pos.loading || pos.loadingTicket) {
      return const AppLoadingState(message: 'Cargando tickets…');
    }
    if (pos.status == PosStatus.error && pos.tickets.isEmpty) {
      return AppErrorState(
        message: pos.errorMessage ?? 'No fue posible cargar los tickets.',
        onRetry: () => pos.load(force: true),
      );
    }

    final tickets = pos.tickets
        .where(
          (ticket) => ticket.folio.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(growable: false);
    final selected = pos.selectedTicket;
    final wide = MediaQuery.sizeOf(context).width >= 980;

    if (!wide && selected != null) {
      return _TicketDetail(ticket: selected);
    }

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
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
                      'Tickets de la sucursal',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Actualizar',
                      onPressed: () => pos.load(force: true),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (pos.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    pos.errorMessage!,
                    style: const TextStyle(color: AppColors.destructive),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar folio…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: tickets.isEmpty
                      ? const OperationalEmptyState(
                          title: 'Sin tickets',
                          message:
                              'No hay ventas registradas para este filtro en '
                              'la sucursal activa.',
                        )
                      : Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Folio')),
                                DataColumn(label: Text('Fecha')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Método')),
                                DataColumn(label: Text('Total'), numeric: true),
                                DataColumn(label: Text('')),
                              ],
                              rows: [
                                for (final ticket in tickets)
                                  DataRow(
                                    selected: selected?.id == ticket.id,
                                    cells: [
                                      DataCell(Text(ticket.folio)),
                                      DataCell(
                                        Text(_dateTime(ticket.createdAt)),
                                      ),
                                      DataCell(
                                        _PaymentBadge(
                                          status: ticket.paymentStatus,
                                        ),
                                      ),
                                      DataCell(
                                        Text(ticket.paymentMethod.label),
                                      ),
                                      DataCell(
                                        Text(
                                          AppFormatters.currency(ticket.total),
                                        ),
                                      ),
                                      DataCell(
                                        IconButton(
                                          onPressed: () => context.go(
                                            '/app/pos/tickets/${ticket.id}',
                                          ),
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (selected != null && wide)
          SizedBox(width: 390, child: _TicketDetail(ticket: selected)),
      ],
    );
  }
}

class _TicketDetail extends StatelessWidget {
  const _TicketDetail({required this.ticket});
  final PosTicket ticket;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.folio,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => context.go('/app/pos/tickets'),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            '${_dateTime(ticket.createdAt)} · Cajero '
            '${_shortId(ticket.cashierId)}',
          ),
          const SizedBox(height: 8),
          _PaymentBadge(status: ticket.paymentStatus),
          const Divider(height: 28),
          Expanded(
            child: ListView(
              children: [
                for (final item in ticket.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName),
                    subtitle: Text(
                      '${item.quantity} × '
                      '${AppFormatters.currency(item.unitPrice)}',
                    ),
                    trailing: Text(AppFormatters.currency(item.lineTotal)),
                  ),
              ],
            ),
          ),
          const Divider(),
          _DetailAmount('Subtotal', ticket.subtotal),
          if (ticket.discountAmount > 0)
            _DetailAmount('Descuentos', -ticket.discountAmount),
          _DetailAmount('Total', ticket.total, strong: true),
          if (ticket.changeGiven != null)
            _DetailAmount('Cambio', ticket.changeGiven!),
          if (ticket.paymentStatus == PaymentStatus.pending) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => context.go('/app/pos/checkout'),
                icon: const Icon(Icons.schedule),
                label: const Text('Reanudar pago pendiente'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.status});
  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PaymentStatus.completed => ('COMPLETADO', AppColors.success),
      PaymentStatus.pending => ('PENDIENTE', AppColors.warning),
      PaymentStatus.failed => ('FALLIDO', AppColors.destructive),
      PaymentStatus.refunded => ('REEMBOLSADO', AppColors.primary),
      PaymentStatus.unknown => ('SIN ESTADO', AppColors.mutedForeground),
    };
    return AppBadge(label: label, color: color);
  }
}

class _DetailAmount extends StatelessWidget {
  const _DetailAmount(this.label, this.value, {this.strong = false});
  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          AppFormatters.currency(value),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            fontSize: strong ? 20 : 14,
          ),
        ),
      ],
    ),
  );
}

String _dateTime(DateTime? value) {
  if (value == null) return 'Sin fecha';
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${AppFormatters.date(value)} $hour:$minute';
}

String _shortId(String value) =>
    value.length <= 8 ? value : '${value.substring(0, 8)}…';
