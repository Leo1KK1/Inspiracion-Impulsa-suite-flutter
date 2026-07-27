import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

class SuperadminLoginPage extends StatefulWidget {
  const SuperadminLoginPage({super.key});

  @override
  State<SuperadminLoginPage> createState() => _SuperadminLoginPageState();
}

class _SuperadminLoginPageState extends State<SuperadminLoginPage> {
  final _key = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/superadmin/dashboard');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        if (MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop)
          Expanded(
            child: Container(
              color: AppColors.superadminSidebar,
              padding: const EdgeInsets.all(52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Impulsa Suite',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Control total de la plataforma.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tenants, facturación, salud del sistema y operaciones globales.',
                    style: TextStyle(color: Color(0xFFC7D2FE), height: 1.5),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 42,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bienvenida de nuevo',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        initialValue: 'admin@impulsa.io',
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'El correo es obligatorio.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: 'demo1234',
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'La contraseña es obligatoria.'
                            : null,
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: const Text('Iniciar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
