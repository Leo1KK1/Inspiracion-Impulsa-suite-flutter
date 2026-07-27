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
    final pos = context.read<PosController>();
    if (pos.tickets.isEmpty) pos.load();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosController>();
    if (pos.loading) {
      return const AppLoadingState(message: 'Cargando tickets…');
    }
    final tickets = pos.tickets
        .where(
          (ticket) => ticket.folio.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final selected = widget.ticketId == null
        ? null
        : pos.tickets
              .where((ticket) => ticket.id == widget.ticketId)
              .firstOrNull;
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
                      'Tickets del turno',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
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
                  child: Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Folio')),
                          DataColumn(label: Text('Hora')),
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
                                DataCell(Text(ticket.time)),
                                DataCell(_TicketBadge(status: ticket.status)),
                                DataCell(Text(ticket.method.name)),
                                DataCell(
                                  Text(AppFormatters.currency(ticket.total)),
                                ),
                                DataCell(
                                  IconButton(
                                    onPressed: () => context.go(
                                      '/app/pos/tickets/${ticket.id}',
                                    ),
                                    icon: const Icon(Icons.visibility_outlined),
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
        if (selected != null && MediaQuery.sizeOf(context).width >= 980)
          SizedBox(width: 360, child: _TicketDetail(ticket: selected)),
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
              Text(ticket.folio, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => context.go('/app/pos/tickets'),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text('${ticket.time} · ${ticket.cashier}'),
          const Divider(height: 28),
          for (final line in ticket.lines)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.product.name),
              subtitle: Text('${line.quantity} × ${line.product.price}'),
              trailing: Text(
                AppFormatters.currency(line.product.price * line.quantity),
              ),
            ),
          const Spacer(),
          const Divider(),
          Row(
            children: [
              const Text('Total'),
              const Spacer(),
              Text(
                AppFormatters.currency(ticket.total),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AppSuccessFeedback.show(
                context,
                'Ticket enviado a impresión.',
              ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Imprimir ticket'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TicketBadge extends StatelessWidget {
  const _TicketBadge({required this.status});
  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final name = status.name;
    final color = switch (name) {
      'completed' => AppColors.success,
      'cancelled' => AppColors.destructive,
      _ => AppColors.primary,
    };
    return AppBadge(label: name.toUpperCase(), color: color);
  }
}
