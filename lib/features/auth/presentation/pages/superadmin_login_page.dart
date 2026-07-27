import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../superadmin/presentation/controllers/superadmin_controller.dart';

class SuperadminLoginPage extends StatefulWidget {
  const SuperadminLoginPage({super.key});

  @override
  State<SuperadminLoginPage> createState() => _SuperadminLoginPageState();
}

class _SuperadminLoginPageState extends State<SuperadminLoginPage> {
  final _key = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    final controller = context.read<SuperadminController>();
    final success = await controller.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (success && mounted) context.go('/superadmin/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SuperadminController>();
    return Scaffold(
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
                      'Administra tenants, módulos y propietarios desde el contexto global.',
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
                          'Acceso Superadmin',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                          ),
                          validator: (value) =>
                              value == null || !value.contains('@')
                              ? 'Ingresa un correo válido.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.length < 8
                              ? 'La contraseña debe tener al menos 8 caracteres.'
                              : null,
                          onFieldSubmitted: (_) {
                            if (!controller.saving) _submit();
                          },
                        ),
                        if (controller.errorMessage case final message?) ...[
                          const SizedBox(height: 14),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: controller.saving ? null : _submit,
                          icon: controller.saving
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
}
