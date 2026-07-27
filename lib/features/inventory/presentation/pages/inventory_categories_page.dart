import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../../data/models/inventory_models.dart';
import '../controllers/inventory_controller.dart';

class InventoryCategoriesPage extends StatefulWidget {
  const InventoryCategoriesPage({super.key});

  @override
  State<InventoryCategoriesPage> createState() =>
      _InventoryCategoriesPageState();
}

class _InventoryCategoriesPageState extends State<InventoryCategoriesPage> {
  @override
  void initState() {
    super.initState();
    final controller = context.read<InventoryController>();
    if (controller.status == InventoryStatus.idle) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();
    final isOwner = context.watch<TenantSessionController>().isOwner;
    if (inventory.status == InventoryStatus.loading &&
        inventory.categories.isEmpty) {
      return const AppLoadingState(message: 'Cargando categorías…');
    }
    if (inventory.status == InventoryStatus.error) {
      return AppErrorState(
        message: inventory.errorMessage ?? 'No fue posible cargar categorías.',
        onRetry: () => inventory.load(force: true),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Categorías',
            subtitle: 'Clasificación global del catálogo del tenant.',
            actions: [
              if (isOwner)
                FilledButton.icon(
                  onPressed: inventory.saving
                      ? null
                      : () => _showCategoryForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva categoría'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (inventory.categories.isEmpty)
            const OperationalEmptyState(
              title: 'Sin categorías',
              message: 'El catálogo todavía no tiene categorías.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth < 700 ? 1 : 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.35,
                ),
                itemCount: inventory.categories.length,
                itemBuilder: (context, index) {
                  final category = inventory.categories[index];
                  final count = inventory.products
                      .where((product) => product.categoryId == category.id)
                      .length;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.category_outlined),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              AppBadge(
                                label: category.isActive
                                    ? 'ACTIVA'
                                    : 'INACTIVA',
                                color: category.isActive
                                    ? AppColors.success
                                    : AppColors.mutedForeground,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            category.code,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.tenantAccent,
                            ),
                          ),
                          Text(
                            category.description.isEmpty
                                ? 'Sin descripción'
                                : category.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text('$count productos'),
                              const Spacer(),
                              if (isOwner)
                                IconButton(
                                  onPressed: inventory.saving
                                      ? null
                                      : () => _showCategoryForm(
                                          context,
                                          category: category,
                                        ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              if (isOwner)
                                IconButton(
                                  onPressed: inventory.saving
                                      ? null
                                      : () => _toggle(context, category),
                                  icon: Icon(
                                    category.isActive
                                        ? Icons.pause_circle_outline
                                        : Icons.play_circle_outline,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggle(BuildContext context, InventoryCategory category) async {
    final controller = context.read<InventoryController>();
    final ok = await controller.changeCategoryStatus(
      category.id,
      !category.isActive,
    );
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage);
  }

  Future<void> _showCategoryForm(
    BuildContext context, {
    InventoryCategory? category,
  }) async {
    final name = TextEditingController(text: category?.name);
    final code = TextEditingController(text: category?.code);
    final description = TextEditingController(text: category?.description);
    final key = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(category == null ? 'Nueva categoría' : 'Editar categoría'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              Navigator.pop(dialogContext, {
                'name': name.text.trim(),
                'code': code.text.trim().toUpperCase(),
                if (description.text.trim().isNotEmpty)
                  'description': description.text.trim(),
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    name.dispose();
    code.dispose();
    description.dispose();
    if (payload == null || !context.mounted) return;
    final controller = context.read<InventoryController>();
    final ok = category == null
        ? await controller.createCategory(payload)
        : await controller.updateCategory(category.id, payload);
    if (!context.mounted) return;
    _feedback(context, ok, controller.errorMessage);
  }

  static String? _required(String? value) =>
      value == null || value.trim().length < 2
      ? 'Ingresa al menos 2 caracteres.'
      : null;

  static void _feedback(BuildContext context, bool ok, String? error) {
    if (ok) {
      AppSuccessFeedback.show(context, 'Categoría guardada en el backend.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No fue posible guardar la categoría.'),
        ),
      );
    }
  }
}
