import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';
import '../../data/models/finance_models.dart';
import '../controllers/finance_controller.dart';

class ExpenseFormDialog extends StatefulWidget {
  const ExpenseFormDialog({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _key = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String? _categoryId;
  String? _branchId;
  ExpenseType _type = ExpenseType.variable;
  DateTime _date = DateTime.now();

  bool get _editing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    final finance = context.read<FinanceController>();
    if (expense != null) {
      _amount.text = expense.amount.toStringAsFixed(2);
      _notes.text = expense.notes ?? '';
      _categoryId = expense.categoryId;
      _branchId = expense.branchId;
      _type = expense.expenseType;
      _date = expense.expenseDate;
    } else {
      final options = finance.categoryOptions;
      _categoryId = options.isEmpty ? null : options.first.id;
      _branchId = finance.isOwner ? finance.selectedBranchId : null;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceController>();
    final session = context.watch<TenantSessionController>();
    final categoryOptions = [...finance.categoryOptions];
    if (_categoryId != null &&
        !categoryOptions.any((category) => category.id == _categoryId)) {
      if (widget.expense != null) {
        categoryOptions.add(widget.expense!.category);
      } else {
        _categoryId = categoryOptions.firstOrNull?.id;
      }
    }
    final branchOptions = [
      for (final branch in session.branches.where((item) => item.isActive))
        MapEntry(branch.id, '${branch.name} · ${branch.code}'),
    ];
    final expenseBranch = widget.expense?.branch;
    if (expenseBranch != null &&
        !branchOptions.any((item) => item.key == expenseBranch.id)) {
      branchOptions.add(
        MapEntry(
          expenseBranch.id,
          '${expenseBranch.name} · ${expenseBranch.code}',
        ),
      );
    }

    return AlertDialog(
      title: Text(
        _editing ? 'Editar gasto operativo' : 'Nuevo gasto operativo',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 620),
        child: Form(
          key: _key,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (finance.errorMessage != null) ...[
                  Text(
                    finance.errorMessage!,
                    style: const TextStyle(color: AppColors.destructive),
                  ),
                  const SizedBox(height: 12),
                ],
                if (categoryOptions.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.warning.withValues(alpha: 0.1),
                    child: Text(
                      finance.isOwner
                          ? 'No hay categorías activas. Crea o activa una '
                                'categoría antes de registrar el gasto.'
                          : 'El backend restringe el catálogo de categorías a '
                                'OWNER. Como no hay gastos previos para derivar '
                                'opciones, ingresa un categoryId activo '
                                'proporcionado por el OWNER.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!finance.isOwner)
                    TextFormField(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'ID de categoría activa',
                      ),
                      onChanged: (value) => _categoryId = value.trim(),
                      validator: (value) => value?.trim().isEmpty != false
                          ? 'Ingresa el categoryId.'
                          : null,
                    ),
                ] else
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final category in categoryOptions)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text('${category.name} · ${category.code}'),
                        ),
                    ],
                    onChanged: (value) => _categoryId = value,
                    validator: (value) =>
                        value == null ? 'Selecciona una categoría.' : null,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          prefixText: r'$ ',
                        ),
                        validator: (value) =>
                            (double.tryParse(value ?? '') ?? 0) <= 0
                            ? 'Debe ser mayor a cero.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ExpenseType>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de gasto',
                        ),
                        items: [
                          for (final type in ExpenseType.values)
                            DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                        ],
                        onChanged: (value) =>
                            _type = value ?? ExpenseType.variable,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: _date.isAfter(DateTime.now())
                          ? DateTime.now()
                          : _date,
                    );
                    if (selected != null) {
                      setState(() => _date = selected);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha'),
                    child: Text(
                      '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/'
                      '${_date.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (finance.isOwner)
                  DropdownButtonFormField<String>(
                    initialValue: _branchId ?? '_global',
                    decoration: const InputDecoration(
                      labelText: 'Alcance del gasto',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '_global',
                        child: Text('Global · sin sucursal'),
                      ),
                      for (final branch in branchOptions)
                        DropdownMenuItem<String>(
                          value: branch.key,
                          child: Text(branch.value),
                        ),
                    ],
                    onChanged: (value) =>
                        _branchId = value == '_global' ? null : value,
                  )
                else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.store_outlined),
                    title: const Text('Sucursal activa'),
                    subtitle: Text(
                      session.session?.activeBranchName ??
                          finance.activeBranchId ??
                          'Sin sucursal',
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    helperText:
                        'El contrato HU05 no incluye folio, IVA, método de '
                        'pago ni comprobante.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: finance.saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed:
              finance.saving || (categoryOptions.isEmpty && finance.isOwner)
              ? null
              : _save,
          child: finance.saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_editing ? 'Guardar cambios' : 'Registrar gasto'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _categoryId == null) return;
    final finance = context.read<FinanceController>();
    final mutation = ExpenseMutation(
      categoryId: _categoryId!,
      amount: double.parse(_amount.text),
      expenseDate: _date,
      expenseType: _type,
      notes: _notes.text,
      branchId: finance.isOwner ? _branchId : null,
    );
    final success = _editing
        ? await finance.updateExpense(widget.expense!.id, mutation)
        : await finance.createExpense(mutation);
    if (!mounted || !success) return;
    AppSuccessFeedback.show(
      context,
      _editing ? 'Gasto actualizado.' : 'Gasto registrado.',
    );
    Navigator.pop(context, true);
  }
}
