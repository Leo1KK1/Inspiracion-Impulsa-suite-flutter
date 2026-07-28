import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../data/models/finance_models.dart';
import '../controllers/finance_controller.dart';

class ExpenseCategoriesPage extends StatefulWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  State<ExpenseCategoriesPage> createState() => _ExpenseCategoriesPageState();
}

class _ExpenseCategoriesPageState extends State<ExpenseCategoriesPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    final finance = context.read<FinanceController>();
    if (finance.isOwner && finance.status == FinanceStatus.idle) {
      finance.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    if (!finance.canManageCategories) {
      return const AccessDeniedPage(requiredRoles: ['OWNER']);
    }
    if (finance.status == FinanceStatus.loading && finance.categories.isEmpty) {
      return const AppLoadingState(message: 'Cargando categorías…');
    }
    if (finance.status == FinanceStatus.error && finance.categories.isEmpty) {
      return AppErrorState(
        message: finance.errorMessage ?? 'No fue posible cargar categorías.',
        onRetry: () => finance.load(force: true),
      );
    }

    final categories = finance.categories
        .where(
          (category) =>
              category.name.toLowerCase().contains(_query.toLowerCase()) ||
              category.code.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList(growable: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Categorías de gasto',
            subtitle: 'Catálogo OWNER para clasificar los egresos operativos.',
            actions: [
              FilledButton.icon(
                onPressed: finance.saving
                    ? null
                    : () => showDialog<bool>(
                        context: context,
                        builder: (_) => const _CategoryFormDialog(),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Nueva categoría'),
              ),
            ],
          ),
          if (finance.status == FinanceStatus.loading)
            const LinearProgressIndicator(minHeight: 2),
          if (finance.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              finance.errorMessage!,
              style: const TextStyle(color: AppColors.destructive),
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Buscar nombre o código…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const OperationalEmptyState(
              title: 'Sin categorías',
              message: 'El backend no devolvió categorías para esta búsqueda.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth < 760 ? 1 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth < 760 ? 2 : 1.7,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                child: const Icon(Icons.category_outlined),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Text(
                                      category.code,
                                      style: const TextStyle(
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
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
                          const SizedBox(height: 14),
                          Text(
                            category.description?.trim().isNotEmpty == true
                                ? category.description!
                                : 'Sin descripción',
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: finance.saving
                                    ? null
                                    : () => showDialog<bool>(
                                        context: context,
                                        builder: (_) => _CategoryFormDialog(
                                          category: category,
                                        ),
                                      ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Editar'),
                              ),
                              IconButton(
                                tooltip: category.isActive
                                    ? 'Desactivar'
                                    : 'Activar',
                                onPressed: finance.saving
                                    ? null
                                    : () => _toggle(context, finance, category),
                                icon: Icon(
                                  category.isActive
                                      ? Icons.toggle_on
                                      : Icons.toggle_off,
                                  color: category.isActive
                                      ? AppColors.success
                                      : AppColors.mutedForeground,
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

  Future<void> _toggle(
    BuildContext context,
    FinanceController finance,
    ExpenseCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          category.isActive ? 'Desactivar categoría' : 'Activar categoría',
        ),
        content: Text(
          category.isActive
              ? 'La categoría dejará de estar disponible para nuevos gastos.'
              : 'La categoría volverá a estar disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await finance.updateCategory(
      category.id,
      ExpenseCategoryMutation(
        name: category.name,
        description: category.description,
        isActive: !category.isActive,
      ),
    );
    if (context.mounted && success) {
      AppSuccessFeedback.show(context, 'Estado de categoría actualizado.');
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({this.category});

  final ExpenseCategory? category;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _description = TextEditingController();
  bool _active = true;

  bool get _editing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    if (category != null) {
      _name.text = category.name;
      _code.text = category.code;
      _description.text = category.description ?? '';
      _active = category.isActive;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    return AlertDialog(
      title: Text(_editing ? 'Editar categoría' : 'Nueva categoría'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Mínimo 2 caracteres.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _code,
                enabled: !_editing,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  helperText: 'El backend no permite editarlo después.',
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  return length < 2 || length > 30
                      ? 'Usa entre 2 y 30 caracteres.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (value) => setState(() => _active = value),
                title: const Text('Categoría activa'),
              ),
              if (finance.errorMessage != null)
                Text(
                  finance.errorMessage!,
                  style: const TextStyle(color: AppColors.destructive),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: finance.saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: finance.saving ? null : _save,
          child: finance.saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final finance = context.read<FinanceController>();
    final mutation = ExpenseCategoryMutation(
      name: _name.text,
      code: _editing ? null : _code.text.toUpperCase(),
      description: _description.text,
      isActive: _active,
    );
    final success = _editing
        ? await finance.updateCategory(widget.category!.id, mutation)
        : await finance.createCategory(mutation);
    if (!mounted || !success) return;
    AppSuccessFeedback.show(context, 'Categoría guardada.');
    Navigator.pop(context, true);
  }
}
