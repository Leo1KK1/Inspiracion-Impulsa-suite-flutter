import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../session/presentation/controllers/tenant_session_controller.dart';

class TenantLoginPage extends StatefulWidget {
  const TenantLoginPage({super.key});

  @override
  State<TenantLoginPage> createState() => _TenantLoginPageState();
}

class _TenantLoginPageState extends State<TenantLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _tenantSlug = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _tenantSlug.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<TenantSessionController>().loginTenant(
      tenantSlug: _tenantSlug.text,
      email: _email.text,
      password: _password.text,
    );
    if (success && mounted) context.go('/app/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<TenantSessionController>();
    final loading = session.status == SessionStatus.restoring;
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop)
            const Expanded(flex: 4, child: _LoginHero()),
          Expanded(
            flex: 7,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Brand(),
                          const SizedBox(height: 46),
                          Text(
                            'Inicia sesión',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Ingresa los datos reales de tu organización.',
                            style: TextStyle(color: AppColors.mutedForeground),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _tenantSlug,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Identificador del negocio',
                              hintText: 'mi-negocio',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo corporativo',
                              hintText: 'usuario@tuempresa.com',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) =>
                                value != null && value.contains('@')
                                ? null
                                : 'Ingresa un correo válido.',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => loading ? null : _submit(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
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
                                value != null && value.length >= 8
                                ? null
                                : 'Usa al menos 8 caracteres.',
                          ),
                          if (session.errorMessage case final error?) ...[
                            const SizedBox(height: 14),
                            Text(
                              error,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: loading ? null : _submit,
                            icon: loading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward),
                            label: Text(
                              loading ? 'Verificando…' : 'Entrar al workspace',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.tenantAccent,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _SecurityNotice(),
                        ],
                      ),
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

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: Color(0x1A0D9488),
        child: Icon(Icons.storefront, color: AppColors.tenantAccent),
      ),
      SizedBox(width: 10),
      Text(
        'Impulsa Suite',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ],
  );
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.tenantSidebar, Color(0xFF0A3D35)],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Icon(
            Icons.storefront_outlined,
            color: Color(0xFF5EEAD4),
            size: 46,
          ),
          const SizedBox(height: 24),
          Text(
            'Tu negocio,\nsiempre operativo.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestiona sucursales, personal y permisos desde un solo workspace.',
            style: TextStyle(color: Color(0xFF94D2CD), height: 1.5),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.muted,
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: const Row(
      children: [
        Icon(Icons.shield_outlined, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'La sesión se valida directamente con el servidor.',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
