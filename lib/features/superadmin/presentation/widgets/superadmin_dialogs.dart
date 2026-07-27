import 'package:flutter/material.dart';

import '../../data/models/superadmin_models.dart';

Future<Map<String, Object?>?> showTenantFormDialog(
  BuildContext context, {
  PlatformTenant? tenant,
}) => showDialog<Map<String, Object?>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _TenantFormDialog(tenant: tenant),
);

Future<Map<String, Object?>?> showOwnerFormDialog(
  BuildContext context, {
  required bool creating,
  OwnerAccount? owner,
}) => showDialog<Map<String, Object?>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _OwnerFormDialog(creating: creating, owner: owner),
);

Future<String?> showStatusDialog(
  BuildContext context, {
  required String title,
  required String currentStatus,
  required List<String> statuses,
  required String Function(String status) labelFor,
}) => showDialog<String>(
  context: context,
  builder: (_) => _StatusDialog(
    title: title,
    currentStatus: currentStatus,
    statuses: statuses,
    labelFor: labelFor,
  ),
);

class _TenantFormDialog extends StatefulWidget {
  const _TenantFormDialog({this.tenant});

  final PlatformTenant? tenant;

  @override
  State<_TenantFormDialog> createState() => _TenantFormDialogState();
}

class _TenantFormDialogState extends State<_TenantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _plan;
  late final TextEditingController _branchName;
  late final TextEditingController _branchCode;
  late final TextEditingController _branchAddress;
  bool _retail = false;
  bool _restaurant = false;

  bool get _editing => widget.tenant != null;

  @override
  void initState() {
    super.initState();
    final tenant = widget.tenant;
    _name = TextEditingController(text: tenant?.name);
    _slug = TextEditingController(text: tenant?.slug);
    _email = TextEditingController(text: tenant?.primaryEmail);
    _address = TextEditingController(text: tenant?.address);
    _plan = TextEditingController(text: tenant?.planCode ?? 'BASIC');
    _branchName = TextEditingController();
    _branchCode = TextEditingController();
    _branchAddress = TextEditingController();
    _retail =
        tenant?.modules.any(
          (module) => module.moduleCode == 'RETAIL' && module.isEnabled,
        ) ??
        false;
    _restaurant =
        tenant?.modules.any(
          (module) => module.moduleCode == 'RESTAURANT' && module.isEnabled,
        ) ??
        false;
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _email.dispose();
    _address.dispose();
    _plan.dispose();
    _branchName.dispose();
    _branchCode.dispose();
    _branchAddress.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final payload = <String, Object?>{
      'name': _name.text.trim(),
      'slug': _slug.text.trim().toLowerCase(),
      'primaryEmail': _email.text.trim(),
      if (_editing || _address.text.trim().isNotEmpty)
        'address': _address.text.trim(),
    };
    if (!_editing) {
      payload.addAll({
        'planCode': _plan.text.trim().toUpperCase(),
        if (_branchName.text.trim().isNotEmpty)
          'branchName': _branchName.text.trim(),
        if (_branchCode.text.trim().isNotEmpty)
          'branchCode': _branchCode.text.trim().toUpperCase(),
        if (_branchAddress.text.trim().isNotEmpty)
          'branchAddress': _branchAddress.text.trim(),
        'modules': [
          {'moduleCode': 'CORE', 'isEnabled': true},
          {'moduleCode': 'RETAIL', 'isEnabled': _retail},
          {'moduleCode': 'RESTAURANT', 'isEnabled': _restaurant},
        ],
      });
    }
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_editing ? 'Editar tenant' : 'Nuevo tenant'),
    content: SizedBox(
      width: 650,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: _requiredTwoCharacters,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slug,
                decoration: const InputDecoration(
                  labelText: 'Slug *',
                  helperText: 'Solo minúsculas, números y guiones.',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) return 'Ingresa al menos 2 caracteres.';
                  if (!RegExp(r'^[a-z0-9-]+$').hasMatch(text)) {
                    return 'Usa solo minúsculas, números y guiones.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo principal *',
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Ingresa un correo válido.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Dirección'),
              ),
              if (!_editing) ...[
                const Divider(height: 28),
                TextFormField(
                  controller: _plan,
                  decoration: const InputDecoration(
                    labelText: 'Código de plan *',
                  ),
                  validator: _requiredTwoCharacters,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _branchName,
                  decoration: const InputDecoration(
                    labelText: 'Primera sucursal',
                  ),
                  validator: (value) {
                    if (_branchCode.text.trim().isNotEmpty &&
                        (value?.trim().length ?? 0) < 2) {
                      return 'El nombre es obligatorio si indicas un código.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _branchCode,
                  decoration: const InputDecoration(
                    labelText: 'Código de sucursal',
                  ),
                  validator: (value) {
                    if (_branchName.text.trim().isNotEmpty &&
                        (value?.trim().length ?? 0) < 2) {
                      return 'El código es obligatorio si indicas una sucursal.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _branchAddress,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Dirección de sucursal',
                  ),
                ),
                const Divider(height: 28),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('RETAIL'),
                  value: _retail,
                  onChanged: (value) => setState(() => _retail = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('RESTAURANT'),
                  value: _restaurant,
                  onChanged: (value) => setState(() => _restaurant = value),
                ),
              ],
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
      FilledButton(
        onPressed: _submit,
        child: Text(_editing ? 'Guardar' : 'Crear tenant'),
      ),
    ],
  );
}

class _OwnerFormDialog extends StatefulWidget {
  const _OwnerFormDialog({required this.creating, this.owner});

  final bool creating;
  final OwnerAccount? owner;

  @override
  State<_OwnerFormDialog> createState() => _OwnerFormDialogState();
}

class _OwnerFormDialogState extends State<_OwnerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.owner?.fullName);
    _email = TextEditingController(text: widget.owner?.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final payload = <String, Object?>{
      if (_name.text.trim().isNotEmpty) 'fullName': _name.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      if (_password.text.isNotEmpty) 'password': _password.text,
    };
    if (payload.isEmpty) return;
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.creating ? 'Crear OWNER' : 'Actualizar OWNER'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: widget.creating ? 'Nombre completo *' : 'Nombre',
              ),
              validator: (value) {
                if (widget.creating && (value?.trim().length ?? 0) < 2) {
                  return 'Ingresa al menos 2 caracteres.';
                }
                if ((value?.isNotEmpty ?? false) &&
                    (value?.trim().length ?? 0) < 2) {
                  return 'Ingresa al menos 2 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: widget.creating ? 'Correo *' : 'Correo',
              ),
              validator: (value) {
                if (widget.creating && !(value?.contains('@') ?? false)) {
                  return 'Ingresa un correo válido.';
                }
                if ((value?.isNotEmpty ?? false) &&
                    !(value?.contains('@') ?? false)) {
                  return 'Ingresa un correo válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: widget.creating
                    ? 'Contraseña temporal *'
                    : 'Nueva contraseña',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (widget.creating && (value?.length ?? 0) < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres.';
                }
                if ((value?.isNotEmpty ?? false) && (value?.length ?? 0) < 8) {
                  return 'La contraseña debe tener al menos 8 caracteres.';
                }
                return null;
              },
            ),
            if (!widget.creating && widget.owner == null) ...[
              const SizedBox(height: 12),
              const Text(
                'El contrato actual no permite consultar al OWNER. Envía únicamente los campos que quieras cambiar.',
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(widget.creating ? 'Crear OWNER' : 'Guardar'),
      ),
    ],
  );
}

class _StatusDialog extends StatefulWidget {
  const _StatusDialog({
    required this.title,
    required this.currentStatus,
    required this.statuses,
    required this.labelFor,
  });

  final String title;
  final String currentStatus;
  final List<String> statuses;
  final String Function(String status) labelFor;

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late String _status = widget.currentStatus;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: const InputDecoration(labelText: 'Nuevo estado'),
      items: [
        for (final status in widget.statuses)
          DropdownMenuItem(value: status, child: Text(widget.labelFor(status))),
      ],
      onChanged: (value) => setState(() => _status = value ?? _status),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _status == widget.currentStatus
            ? null
            : () => Navigator.pop(context, _status),
        child: const Text('Confirmar'),
      ),
    ],
  );
}

String? _requiredTwoCharacters(String? value) =>
    (value?.trim().length ?? 0) < 2 ? 'Ingresa al menos 2 caracteres.' : null;
