import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../controllers/waiter_controller.dart';
import '../widgets/order_composer_panel.dart';

class TableSessionPage extends StatefulWidget {
  const TableSessionPage({super.key, required this.tableId});
  final String tableId;

  @override
  State<TableSessionPage> createState() => _TableSessionPageState();
}

class _TableSessionPageState extends State<TableSessionPage> {
  @override
  void initState() {
    super.initState();
    final waiter = context.read<WaiterController>();
    if (waiter.menu.isEmpty) waiter.load();
  }

  @override
  Widget build(BuildContext context) {
    final waiter = context.watch<WaiterController>();
    if (waiter.loading) {
      return const AppLoadingState(message: 'Cargando menú…');
    }
    final compact = MediaQuery.sizeOf(context).width < 980;
    final catalog = _MenuCatalog(waiter: waiter);
    final composer = OrderComposerPanel(
      controller: waiter,
      tableId: widget.tableId,
    );
    return Column(
      children: [
        Material(
          color: Colors.white,
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/app/restaurant/waiter'),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  'Mesa ${widget.tableId.split('-').last}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 10),
                const AppBadge(label: 'OCUPADA', color: AppColors.tenantAccent),
                const Spacer(),
                const Text('5 comensales · 45 min'),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    '/app/restaurant/waiter/split-bill/${widget.tableId}',
                  ),
                  icon: const Icon(Icons.call_split),
                  label: const Text('Dividir cuenta'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: compact
              ? Column(
                  children: [
                    Expanded(child: catalog),
                    Material(
                      elevation: 14,
                      child: ExpansionTile(
                        initiallyExpanded: waiter.order.isNotEmpty,
                        title: Text(
                          'Comanda · ${waiter.order.length} partidas · ${AppFormatters.currency(waiter.total)}',
                        ),
                        children: [SizedBox(height: 430, child: composer)],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: catalog),
                    SizedBox(width: 350, child: composer),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MenuCatalog extends StatefulWidget {
  const _MenuCatalog({required this.waiter});
  final WaiterController waiter;

  @override
  State<_MenuCatalog> createState() => _MenuCatalogState();
}

class _MenuCatalogState extends State<_MenuCatalog> {
  static const categories = [
    'Todos',
    'Entradas',
    'Sopas',
    'Platos fuertes',
    'Postres',
    'Bebidas',
    'Especiales',
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        TextField(
          onChanged: widget.waiter.setQuery,
          decoration: const InputDecoration(
            hintText: 'Buscar productos…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: widget.waiter.category == category,
                    onSelected: (_) => widget.waiter.setCategory(category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (constraints.maxWidth / 220).floor().clamp(
                  2,
                  4,
                ),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.08,
              ),
              itemCount: widget.waiter.filteredMenu.length,
              itemBuilder: (context, index) {
                final product = widget.waiter.filteredMenu[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => widget.waiter.add(product),
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppBadge(
                                label: product.category,
                                color: AppColors.tenantAccent,
                              ),
                              const Spacer(),
                              if (product.popular)
                                const Icon(
                                  Icons.star,
                                  color: AppColors.warning,
                                  size: 18,
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${product.prepMinutes} min',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                AppFormatters.currency(product.price),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              const CircleAvatar(
                                radius: 16,
                                child: Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
