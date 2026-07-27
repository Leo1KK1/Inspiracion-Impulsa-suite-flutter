import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/core/theme/app_theme.dart';
import 'package:impulsa_suite_flutter/features/auth/presentation/pages/home_selector_page.dart';
import 'package:impulsa_suite_flutter/features/session/data/models/tenant_session.dart';
import 'package:impulsa_suite_flutter/features/session/data/repositories/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('la sesión tenant se persiste y restaura con sus claims', () async {
    final store = PreferencesTenantSessionStore();
    final session = _session();
    await store.write(session);

    final restored = await store.read();
    expect(restored?.toJson(), session.toJson());
  });

  test('TenantSession conserva todos los claims al serializar', () {
    final session = _session();
    final restored = TenantSession.fromJson(session.toJson());
    expect(restored.toJson(), session.toJson());
    expect(restored.activeBranchName, 'Centro');
  });

  testWidgets('selector inicial se renderiza sin errores en escritorio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomeSelectorPage()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Superadmin'), findsOneWidget);
    expect(find.text('Tenant workspace'), findsOneWidget);
  });
}

TenantSession _session() => const TenantSession(
  authContext: 'tenant',
  actorId: 'USR-1',
  actorType: 'TENANT_USER',
  tenantId: 'TEN-1',
  tenantName: 'Tenant',
  tenantSlug: 'tenant',
  tenantStatus: 'ACTIVE',
  activeBranchId: 'BR-1',
  roleCodes: ['OWNER'],
  permissions: ['tenant.read'],
  branches: [
    TenantBranchAccess(
      id: 'BR-1',
      name: 'Centro',
      code: 'CENTRO',
      status: 'ACTIVE',
      isPrimary: true,
    ),
  ],
  sessionId: 'SID-1',
  accessToken: 'access',
  refreshToken: 'refresh',
  userName: 'Usuario',
  userEmail: 'usuario@tenant.mx',
);
