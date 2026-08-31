import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../data/models/retail_models.dart';
import '../controllers/retail_controller.dart';

class FittingRoomDetailPage extends StatefulWidget {
  const FittingRoomDetailPage({super.key, required this.roomId});
  final String roomId;
  @override State<FittingRoomDetailPage> createState() => _FittingRoomDetailPageState();
}

class _FittingRoomDetailPageState extends State<FittingRoomDetailPage> {
  final _search = TextEditingController();
  final _client = TextEditingController();
  final Set<String> _forSale = {};
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) context.read<RetailController>().loadRoomDetail(widget.roomId); }); }
  @override void dispose() { _search.dispose(); _client.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final retail = context.watch<RetailController>();
    final room = retail.selectedRoom;
    if (retail.loadingDetail) return const AppLoadingState(message: 'Cargando probador…');
    if (room == null) return AppErrorState(message: retail.errorMessage ?? 'No fue posible cargar el probador.', onRetry: () => retail.loadRoomDetail(widget.roomId));
    final session = room.activeSession;
    return SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xl), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [IconButton(tooltip: 'Volver a probadores', onPressed: () => context.go('/app/retail/floor'), icon: const Icon(Icons.arrow_back)), const SizedBox(width: 8), Expanded(child: Text(room.name, style: Theme.of(context).textTheme.headlineSmall)), _StatusChip(room.status)]),
      if (retail.errorMessage case final error?) ...[const SizedBox(height: 12), _Banner(error)],
      const SizedBox(height: 20),
      if (session == null) _OpenSession(client: _client, saving: retail.saving, onOpen: () async { if (_client.text.trim().isEmpty) return; if (await retail.openSession(room.id, _client.text)) _client.clear(); }) else ...[
        _SessionHeader(session: session), const SizedBox(height: 16),
        _ProductPicker(search: _search, retail: retail, roomId: room.id), const SizedBox(height: 16),
        Text('Prendas registradas', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8),
        if (session.items.isEmpty) const OperationalEmptyState(title: 'Aún no hay prendas', message: 'Busca o escanea una prenda para reservarla durante la prueba.')
        else Card(child: Column(children: [for (final item in session.items) _ItemRow(item: item, selected: _forSale.contains(item.id), onChanged: (value) => setState(() { if (value) {_forSale.add(item.id);} else {_forSale.remove(item.id);} }), onRemove: retail.saving ? null : () => retail.removeItem(room.id, item.id))])),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: retail.saving || session.items.isEmpty ? null : () => _checkout(retail, session), icon: const Icon(Icons.point_of_sale_outlined), label: Text('Liquidar: ${_forSale.length} para venta · ${session.items.length - _forSale.length} devueltas'))),
      ],
    ]))));
  }
  Future<void> _checkout(RetailController retail, FittingRoomSession session) async {
    final ids = session.items.map((item) => item.id).toList(growable: false);
    final sale = _forSale.toList(growable: false);
    final returned = ids.where((id) => !_forSale.contains(id)).toList(growable: false);
    if (!await retail.checkout(sessionId: session.id, returnedItemIds: returned, saleItemIds: sale) || !mounted) return;
    final result = retail.lastCheckoutResult;
    if (result == null) return;
    await showDialog<void>(context: context, builder: (dialog) => AlertDialog(icon: Icon(result.draftId == null ? Icons.assignment_return_outlined : Icons.receipt_long_outlined, color: AppColors.success, size: 42), title: Text(result.draftId == null ? 'Prendas devueltas' : 'Cobro enviado a caja'), content: Text(result.draftId == null ? 'La sesión se cerró y las reservas fueron liberadas.' : 'Se creó el draft de ${AppFormatters.currency(result.total ?? 0)}. El cajero puede cobrarlo desde su cola.'), actions: [FilledButton(onPressed: () { Navigator.pop(dialog); context.go('/app/retail/floor'); }, child: const Text('Listo'))]));
  }
}

class _OpenSession extends StatelessWidget { const _OpenSession({required this.client, required this.saving, required this.onOpen}); final TextEditingController client; final bool saving; final Future<void> Function() onOpen; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Abrir sesión', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 12), TextField(controller: client, textCapitalization: TextCapitalization.words, onSubmitted: (_) => onOpen(), decoration: const InputDecoration(labelText: 'Nombre del cliente', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 14), FilledButton.icon(onPressed: saving ? null : onOpen, icon: const Icon(Icons.meeting_room_outlined), label: const Text('Iniciar prueba'))]))) ; }
class _SessionHeader extends StatelessWidget { const _SessionHeader({required this.session}); final FittingRoomSession session; @override Widget build(BuildContext context) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(session.clientName), subtitle: Text('Atiende: ${session.seller?.fullName ?? 'Vendedor'}'), trailing: Text('${session.items.length} prendas'))); }
class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.search,
    required this.retail,
    required this.roomId,
  });

  final TextEditingController search;
  final RetailController retail;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: search,
              onChanged: retail.searchProducts,
              decoration: const InputDecoration(
                labelText: 'Buscar o escanear prenda',
                hintText: 'SKU, código o nombre',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (retail.loadingProducts) const LinearProgressIndicator(),
            if (retail.searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final product in retail.searchResults.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.sku} · Disponibles: ${product.availableStock}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Agregar prenda',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: retail.saving || product.availableStock <= 0
                        ? null
                        : () async {
                            if (await retail.addItem(roomId, product.id, 1)) {
                              search.clear();
                              retail.searchProducts('');
                            }
                          },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
class _ItemRow extends StatelessWidget { const _ItemRow({required this.item, required this.selected, required this.onChanged, required this.onRemove}); final FittingRoomSessionItem item; final bool selected; final ValueChanged<bool> onChanged; final VoidCallback? onRemove; @override Widget build(BuildContext context) => CheckboxListTile(value: selected, onChanged: (value) => onChanged(value ?? false), title: Text(item.product?.name ?? 'Producto'), subtitle: Text('${item.product?.sku ?? ''} · ${item.quantity} pieza(s)'), secondary: IconButton(tooltip: 'Retirar prenda', onPressed: onRemove, icon: const Icon(Icons.remove_circle_outline)), controlAffinity: ListTileControlAffinity.leading); }
class _StatusChip extends StatelessWidget { const _StatusChip(this.status); final FittingRoomStatus status; @override Widget build(BuildContext context) { final label = switch(status) {FittingRoomStatus.available=>'Disponible',FittingRoomStatus.occupied=>'Ocupado',FittingRoomStatus.needsReview=>'Revisión'}; final color = switch(status) {FittingRoomStatus.available=>AppColors.success,FittingRoomStatus.occupied=>AppColors.tenantAccent,FittingRoomStatus.needsReview=>AppColors.warning}; return Chip(avatar: Icon(Icons.circle, color: color, size: 10), label: Text(label)); } }
class _Banner extends StatelessWidget { const _Banner(this.message); final String message; @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.destructive.withValues(alpha: .08), borderRadius: BorderRadius.circular(AppRadii.md)), child: Text(message)); }
