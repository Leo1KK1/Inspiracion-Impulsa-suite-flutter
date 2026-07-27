import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/features/superadmin/data/models/superadmin_models.dart';

void main() {
  test('PlatformTenant interpreta el contrato real de HU01', () {
    final tenant = PlatformTenant.fromJson({
      'id': 'ten-1',
      'name': 'Empresa Real',
      'slug': 'empresa-real',
      'primaryEmail': 'contacto@empresa.mx',
      'address': 'Centro',
      'status': 'ACTIVE',
      'subscriptions': [
        {'planCode': 'BASIC', 'status': 'ACTIVE'},
      ],
      'modules': [
        {'moduleCode': 'CORE', 'isEnabled': true},
        {'moduleCode': 'RETAIL', 'isEnabled': false},
      ],
      'branches': [
        {
          'id': 'branch-1',
          'name': 'Matriz',
          'code': 'MATRIZ',
          'status': 'ACTIVE',
          'address': 'Centro',
        },
      ],
    });

    expect(tenant.id, 'ten-1');
    expect(tenant.planCode, 'BASIC');
    expect(tenant.enabledModuleCount, 1);
    expect(tenant.branches.single.code, 'MATRIZ');
  });

  test('SuperadminSession conserva el contexto separado al serializar', () {
    final session = SuperadminSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      authContext: 'superadmin',
      sessionId: 'session-1',
      user: const SuperadminUser(
        id: 'user-1',
        fullName: 'Super Admin',
        email: 'admin@impulsa.mx',
        roleCodes: ['SUPERADMIN'],
      ),
    );

    final restored = SuperadminSession.fromJson(session.toJson());

    expect(restored.isSuperadmin, isTrue);
    expect(restored.sessionId, 'session-1');
    expect(restored.user.roleCodes, ['SUPERADMIN']);
  });
}
