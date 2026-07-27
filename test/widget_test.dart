import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/core/theme/app_theme.dart';
import 'package:impulsa_suite_flutter/features/auth/presentation/pages/home_selector_page.dart';
import 'package:impulsa_suite_flutter/features/session/data/models/tenant_session.dart';
import 'package:impulsa_suite_flutter/features/session/data/repositories/session_repository.dart';
import 'package:impulsa_suite_flutter/features/session/presentation/controllers/tenant_session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('la sesión tenant se persiste y restaura con sus claims', () async {
    final repository = PreferencesSessionRepository();
    final controller = TenantSessionController(repository);

    final loggedIn = await controller.loginTenant(
      email: 'm.lopez@grupovega.mx',
      password: 'demo1234',
    );
    expect(loggedIn, isTrue);
    expect(controller.isTenant, isTrue);
    expect(controller.activeBranchId, 'CDMX-01');
    expect(controller.roleCodes, contains('WAITER'));

    final restored = TenantSessionController(repository);
    await restored.restore();
    expect(restored.status, SessionStatus.authenticated);
    expect(restored.session?.tenantId, 'GVS-MX-001');
  });

  test('TenantSession conserva todos los claims al serializar', () {
    final session = TenantSession(
      authContext: 'tenant',
      actorId: 'USR-1',
      actorType: 'employee',
      tenantId: 'TEN-1',
      tenantName: 'Tenant',
      activeBranchId: 'BR-1',
      activeBranchName: 'Centro',
      roleCodes: const ['OWNER'],
      sessionId: 'SID-1',
      accessToken: 'access',
      refreshToken: 'refresh',
      userName: 'Usuario',
      userEmail: 'usuario@tenant.mx',
    );

    final restored = TenantSession.fromJson(session.toJson());
    expect(restored.toJson(), session.toJson());
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
