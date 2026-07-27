import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../controllers/pos_controller.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<PosController>();
    if (controller.status == PosStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosController>();
    if (pos.loading) {
      return const AppLoadingState(message: 'Preparando punto de venta…');
    }
    if (pos.status == PosStatus.error && pos.activeShift == null) {
      return AppErrorState(
        message: pos.errorMessage ?? 'No fue posible abrir el POS.',
        onRetry: () => pos.load(force: true),
      );
    }
    if (!pos.shiftOpen) {
      return OperationalEmptyState(
        title: 'Caja cerrada',
        message:
            'Abre un turno en la sucursal activa antes de registrar ventas.',
        actionLabel: 'Abrir turno',
        onAction: () => context.go('/app/pos/shifts/open'),
      );
    }

    final compact = MediaQuery.sizeOf(context).width < 980;
    final catalog = _Catalog(pos: pos);
    final cart = _CartPanel(pos: pos);
    return Column(
      children: [
        if (pos.errorMessage != null)
          MaterialBanner(
            content: Text(pos.errorMessage!),
            leading: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
            ),
            actions: [
              TextButton(
                onPressed: pos.clearError,
                child: const Text('Cerrar'),
              ),
            ],
          ),
        if (pos.hasPendingPayment)
          MaterialBanner(
            content: Text(
              'La venta ${pos.pendingSale?.folio ?? ''} tiene un pago con '
              'tarjeta pendiente. Debes resolverlo antes de iniciar otra venta.',
            ),
            leading: const Icon(Icons.schedule, color: AppColors.warning),
            actions: [
              FilledButton.tonal(
                onPressed: () => context.go('/app/pos/checkout'),
                child: const Text('Reanudar pago'),
              ),
            ],
          ),
        Expanded(
          child: compact
              ? Column(
                  children: [
                    Expanded(child: catalog),
                    Material(
                      elevation: 12,
                      child: ExpansionTile(
                        initiallyExpanded: pos.cart.isNotEmpty,
                        title: Text(
                          'Venta actual · ${pos.cart.length} partidas · '
                          '${AppFormatters.currency(pos.total)}',
                        ),
                        children: [SizedBox(height: 350, child: cart)],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: catalog),
                    SizedBox(width: 380, child: cart),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({required this.pos});
  final PosController pos;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [
        TextField(
          onChanged: pos.setQuery,
          onSubmitted: pos.searchNow,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nombre, SKU o código de barras…',
            prefixIcon: Icon(Icons.search),
            helperText:
                'La búsqueda consulta el catálogo de la sucursal activa.',
          ),
        ),
        if (pos.searchingProducts) const LinearProgressIndicator(minHeight: 2),
        if (pos.products.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final category in pos.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: pos.category == category,
                      onSelected: (_) => pos.setCategory(category),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: pos.query.trim().isEmpty
              ? const OperationalEmptyState(
                  title: 'Busca un producto',
                  message:
                      'Escribe un nombre, SKU o escanea un código de barras.',
                )
              : !pos.searchingProducts && pos.filteredProducts.isEmpty
              ? const OperationalEmptyState(
                  title: 'Sin productos disponibles',
                  message:
                      'No hay coincidencias activas con existencia en esta '
                      'sucursal.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = (constraints.maxWidth / 185).floor().clamp(
                      2,
                      5,
                    );
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.02,
                      ),
                      itemCount: pos.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = pos.filteredProducts[index];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            onTap:
                                product.availableStock <= 0 ||
                                    pos.productActionBusy ||
                                    pos.hasPendingPayment
                                ? null
                                : () => pos.add(product),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        child: const Icon(
                                          Icons.inventory_2_outlined,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (product.isLowStock)
                                        const AppBadge(
                                          label: 'STOCK BAJO',
                                          color: AppColors.warning,
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${product.availableStock} '
                                    '${product.unitName} disponibles',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppFormatters.currency(product.salePrice),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.pos});
  final PosController pos;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Venta actual',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text('${pos.cart.length} partidas'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: pos.cart.isEmpty
              ? const OperationalEmptyState(
                  title: 'Carrito vacío',
                  message: 'Selecciona productos para iniciar la venta.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: pos.cart.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final line = pos.cart[index];
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                AppFormatters.currency(line.product.salePrice),
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: pos.hasPendingPayment
                              ? null
                              : () => pos.changeQuantity(line.product, -1),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${line.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          onPressed:
                              pos.hasPendingPayment ||
                                  line.quantity >= line.product.availableStock
                              ? null
                              : () => pos.changeQuantity(line.product, 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TotalLine('Subtotal', pos.subtotal),
              if (pos.discount > 0) _TotalLine('Descuentos', -pos.discount),
              const Divider(),
              _TotalLine('Total', pos.total, emphasized: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      pos.cart.isEmpty ||
                          pos.hasPendingPayment ||
                          !pos.shiftOpen
                      ? null
                      : () => context.go('/app/pos/checkout'),
                  icon: const Icon(Icons.credit_card),
                  label: const Text('Cobrar'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TotalLine extends StatelessWidget {
  const _TotalLine(this.label, this.value, {this.emphasized = false});
  final String label;
  final double value;
  final bool emphasized;

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
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
            fontSize: emphasized ? 20 : 14,
          ),
        ),
      ],
    ),
  );
}
