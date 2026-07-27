import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_states.dart';
import '../../data/models/finance_models.dart';
import '../controllers/finance_controller.dart';

class ExpenseFormDialog extends StatefulWidget {
  const ExpenseFormDialog({super.key});

  @override
  State<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends State<ExpenseFormDialog> {
  final _key = GlobalKey<FormState>();
  final _concept = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'Renta';
  String _branch = 'CDMX-01';
  ExpensePaymentMethod _method = ExpensePaymentMethod.transfer;
  DateTime _date = DateTime.now();
  String? _receipt;

  @override
  void dispose() {
    _concept.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nuevo gasto operativo'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _concept,
                decoration: const InputDecoration(
                  labelText: 'Concepto del gasto',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        for (final item in [
                          'Renta',
                          'Nómina',
                          'Servicios',
                          'Mantenimiento',
                          'Marketing',
                          'Uniformes',
                          'Tecnología',
                          'Seguros',
                        ])
                          DropdownMenuItem(value: item, child: Text(item)),
                      ],
                      onChanged: (value) => _category = value ?? _category,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _branch,
                      decoration: const InputDecoration(labelText: 'Sucursal'),
                      items: [
                        for (final item in [
                          'CDMX-01',
                          'CDMX-02',
                          'GDL-01',
                          'MTY-01',
                        ])
                          DropdownMenuItem(value: item, child: Text(item)),
                      ],
                      onChanged: (value) => _branch = value ?? _branch,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
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
                    child: InkWell(
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDate: _date,
                        );
                        if (selected != null) {
                          setState(() => _date = selected);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha'),
                        child: Text(
                          '${_date.day}/${_date.month}/${_date.year}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ExpensePaymentMethod>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Método de pago'),
                items: [
                  for (final method in ExpensePaymentMethod.values)
                    DropdownMenuItem(
                      value: method,
                      child: Text(method.name.toUpperCase()),
                    ),
                ],
                onChanged: (value) => _method = value ?? _method,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notas internas'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'xml', 'jpg', 'jpeg', 'png'],
                      withData: true,
                    );
                    if (!context.mounted) return;
                    if (result != null) {
                      final file = result.files.single;
                      if ((file.size / 1024 / 1024) > 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'El comprobante no puede superar 8 MB.',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => _receipt = file.name);
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(_receipt ?? 'Adjuntar PDF, XML o imagen'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar gasto')),
    ],
  );

  void _save() {
    if (!_key.currentState!.validate()) return;
    final controller = context.read<FinanceController>();
    final amount = double.parse(_amount.text);
    controller.addExpense(
      Expense(
        id: 'e${controller.expenses.length + 1}',
        folio:
            'GTO-${(controller.expenses.length + 50).toString().padLeft(4, '0')}',
        concept: _concept.text,
        category: _category,
        branchId: _branch,
        date: _date,
        amount: amount,
        tax: amount * 0.16,
        method: _method,
        status: ExpenseStatus.pending,
        notes: _notes.text,
        createdBy: 'M. López',
        hasReceipt: _receipt != null,
      ),
    );
    Navigator.pop(context);
    AppSuccessFeedback.show(context, 'Gasto registrado correctamente.');
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;
}
