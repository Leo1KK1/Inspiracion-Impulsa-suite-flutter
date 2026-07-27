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
  static const _mockEmail = 'm.lopez@grupovega.mx';
  static const _mockPassword = 'demo1234';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: _mockEmail);
  final _passwordController = TextEditingController(text: _mockPassword);
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? get _resolvedTenant {
    final email = _emailController.text.toLowerCase();
    if (!email.contains('@')) return null;
    if (email.contains('grupovega')) return 'Grupo Vega S.A.';
    if (email.contains('clinicorp')) return 'Clinicorp LATAM';
    if (email.contains('biofarma')) return 'BioFarma MX';
    if (email.contains('hotelgrup')) return 'HotelGrup Caribe';
    return 'Tenant detectado';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<TenantSessionController>();
    final success = await session.loginTenant(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) context.go('/app/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<TenantSessionController>().status;
    final loading = status == SessionStatus.restoring;
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
                            'Usa el correo de tu organización para acceder.',
                            style: TextStyle(color: AppColors.mutedForeground),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Correo corporativo',
                              hintText: 'usuario@tuempresa.com',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Ingresa un correo corporativo válido.';
                              }
                              return null;
                            },
                          ),
                          if (_resolvedTenant case final tenant?) ...[
                            const SizedBox(height: 9),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.tenantAccent.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.tenantAccent,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Workspace detectado: $tenant',
                                      style: const TextStyle(
                                        color: AppColors.tenantAccent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
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
                            validator: (value) => value == null || value.isEmpty
                                ? 'La contraseña es obligatoria.'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Checkbox(value: false, onChanged: (_) {}),
                              const Text('Recordarme'),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Olvidé mi contraseña'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
            'Gestiona sucursales, inventario, ventas y restaurante desde un solo workspace.',
            style: TextStyle(color: Color(0xFF94D2CD), height: 1.5),
          ),
          const Spacer(),
          for (final module in ['Restaurante', 'Retail', 'Logística'])
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF5EEAD4),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(module, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
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
            'Sesión cifrada. Acceso limitado a usuarios autorizados.',
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
