import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/retail_models.dart';
import '../controllers/retail_controller.dart';

class RetailFloorPage extends StatefulWidget {
  const RetailFloorPage({super.key});

  @override
  State<RetailFloorPage> createState() => _RetailFloorPageState();
}

class _RetailFloorPageState extends State<RetailFloorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RetailController>().loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final retail = context.watch<RetailController>();
    if (retail.loadingRooms && retail.rooms.isEmpty) {
      return const AppLoadingState(message: 'Cargando probadores…');
    }
    if (retail.errorMessage != null && retail.rooms.isEmpty) {
      return AppErrorState(
        message: retail.errorMessage!,
        onRetry: () => retail.loadRooms(force: true),
      );
    }
    final counts = {for (final state in FittingRoomStatus.values) state: retail.rooms.where((room) => room.status == state).length};
    return RefreshIndicator(
      onRefresh: () => retail.loadRooms(force: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageHeader(
            title: 'Probadores',
            subtitle: 'Estado en tiempo real de la sucursal activa.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/app/retail/drafts'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Cobros pendientes'),
              ),
              IconButton.outlined(
                tooltip: 'Actualizar probadores',
                onPressed: retail.loadingRooms ? null : () => retail.loadRooms(force: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (retail.errorMessage case final message?) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: message),
          ],
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width < 700 ? 1 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              _Metric('Disponibles', '${counts[FittingRoomStatus.available]}', Icons.check_circle_outline, AppColors.success),
              _Metric('Ocupados', '${counts[FittingRoomStatus.occupied]}', Icons.person_outline, AppColors.tenantAccent),
              _Metric('Revisión', '${counts[FittingRoomStatus.needsReview]}', Icons.warning_amber_outlined, AppColors.warning),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 230,
            child: DropdownButtonFormField<FittingRoomStatus?>(
              initialValue: retail.statusFilter,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final state in FittingRoomStatus.values) DropdownMenuItem(value: state, child: Text(_statusLabel(state))),
              ],
              onChanged: retail.setStatusFilter,
            ),
          ),
          const SizedBox(height: 16),
          if (retail.filteredRooms.isEmpty)
            const OperationalEmptyState(title: 'Sin probadores', message: 'No hay probadores para el filtro seleccionado.')
          else
            LayoutBuilder(builder: (context, constraints) {
              final columns = (constraints.maxWidth / 220).floor().clamp(1, 5);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: retail.filteredRooms.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15),
                itemBuilder: (_, index) => _RoomCard(room: retail.filteredRooms[index]),
              );
            }),
        ]),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
  final FittingRoom room;
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(room.status);
    final session = room.activeSession;
    return Semantics(
      button: true,
      label: '${room.name}, ${_statusLabel(room.status)}',
      child: Material(
        color: color.withValues(alpha: .08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg), side: BorderSide(color: color.withValues(alpha: .35))),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () => context.go('/app/retail/floor/${room.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(room.name, style: Theme.of(context).textTheme.titleMedium)), Icon(Icons.circle, size: 11, color: color)]),
              Text(_statusLabel(room.status), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(session == null ? 'Listo para atender' : session.clientName, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (session != null) Text('${session.items.length} prendas · ${session.openedAt.hour.toString().padLeft(2, '0')}:${session.openedAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label, value; final IconData icon; final Color color;
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: color), title: Text(label), trailing: Text(value, style: Theme.of(context).textTheme.headlineSmall)));
}
class _ErrorBanner extends StatelessWidget { const _ErrorBanner({required this.message}); final String message; @override Widget build(BuildContext context) => Card(child: ListTile(tileColor: AppColors.destructive.withValues(alpha: .08), leading: const Icon(Icons.error_outline, color: AppColors.destructive), title: Text(message))); }
String _statusLabel(FittingRoomStatus state) => switch (state) { FittingRoomStatus.available => 'Disponible', FittingRoomStatus.occupied => 'Ocupado', FittingRoomStatus.needsReview => 'Revisión' };
Color _statusColor(FittingRoomStatus state) => switch (state) { FittingRoomStatus.available => AppColors.success, FittingRoomStatus.occupied => AppColors.tenantAccent, FittingRoomStatus.needsReview => AppColors.warning };
