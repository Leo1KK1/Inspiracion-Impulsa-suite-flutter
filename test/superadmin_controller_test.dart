import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/features/superadmin/data/models/superadmin_models.dart';
import 'package:impulsa_suite_flutter/features/superadmin/data/repositories/superadmin_repository.dart';
import 'package:impulsa_suite_flutter/features/superadmin/presentation/controllers/superadmin_controller.dart';

void main() {
  test('login y carga de tenants usan el repositorio HU01', () async {
    final repository = _FakeSuperadminRepository();
    final controller = SuperadminController(repository);

    final loggedIn = await controller.login(
      email: 'admin@impulsa.mx',
      password: 'password123',
    );
    await controller.load();

    expect(loggedIn, isTrue);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.tenants.single.name, 'Empresa API');
    expect(repository.loginCalls, 1);
    expect(repository.listCalls, 1);
  });

  test(
    'cambiar estado reemplaza el tenant con la respuesta del backend',
    () async {
      final repository = _FakeSuperadminRepository();
      final controller = SuperadminController(repository);
      await controller.load();

      final changed = await controller.changeTenantStatus(
        'tenant-1',
        'SUSPENDED',
      );

      expect(changed, isTrue);
      expect(controller.tenants.single.status, 'SUSPENDED');
      expect(repository.lastRequestedStatus, 'SUSPENDED');
    },
  );
}

class _FakeSuperadminRepository implements SuperadminRepository {
  int loginCalls = 0;
  int listCalls = 0;
  String? lastRequestedStatus;

  static const user = SuperadminUser(
    id: 'superadmin-1',
    fullName: 'Super Admin',
    email: 'admin@impulsa.mx',
    roleCodes: ['SUPERADMIN'],
  );

  static const session = SuperadminSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    authContext: 'superadmin',
    sessionId: 'session-1',
    user: user,
  );

  PlatformTenant tenant({String status = 'ACTIVE'}) => PlatformTenant(
    id: 'tenant-1',
    name: 'Empresa API',
    slug: 'empresa-api',
    primaryEmail: 'contacto@empresa.mx',
    status: status,
    subscriptions: const [
      TenantSubscription(planCode: 'BASIC', status: 'ACTIVE'),
    ],
    modules: const [TenantModule(moduleCode: 'CORE', isEnabled: true)],
    branches: const [],
  );

  @override
  Future<SuperadminSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return session;
  }

  @override
  Future<SuperadminSession?> restoreSession() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<SuperadminUser> getMe() async => user;

  @override
  Future<TenantPage> getTenants({
    int page = 1,
    int pageSize = 100,
    String? search,
    String? status,
  }) async {
    listCalls++;
    return TenantPage(
      items: [tenant()],
      total: 1,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<PlatformTenant> getTenant(String tenantId) async => tenant();

  @override
  Future<PlatformTenant> createTenant(Map<String, Object?> payload) async =>
      tenant();

  @override
  Future<PlatformTenant> updateTenant(
    String tenantId,
    Map<String, Object?> payload,
  ) async => tenant();

  @override
  Future<PlatformTenant> changeTenantStatus(
    String tenantId,
    String status,
  ) async {
    lastRequestedStatus = status;
    return tenant(status: status);
  }

  @override
  Future<List<TenantModule>> updateTenantModules(
    String tenantId,
    List<TenantModule> modules,
  ) async => modules;

  @override
  Future<OwnerAccount> createOwner(Map<String, Object?> payload) async =>
      const OwnerAccount(
        id: 'owner-1',
        tenantId: 'tenant-1',
        fullName: 'Owner',
        email: 'owner@empresa.mx',
        status: 'ACTIVE',
      );

  @override
  Future<OwnerAccount> updateOwner(
    String tenantId,
    Map<String, Object?> payload,
  ) => createOwner(payload);

  @override
  Future<OwnerAccount> changeOwnerStatus(
    String tenantId,
    String status,
  ) async => OwnerAccount(
    id: 'owner-1',
    tenantId: tenantId,
    fullName: 'Owner',
    email: 'owner@empresa.mx',
    status: status,
  );
}
