import '../models/superadmin_models.dart';

abstract interface class SuperadminRepository {
  Future<List<PlatformTenant>> getTenants();
}

class MockSuperadminRepository implements SuperadminRepository {
  @override
  Future<List<PlatformTenant>> getTenants() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return [
      PlatformTenant(
        id: 'GVS-MX-001',
        name: 'Grupo Vega S.A.',
        plan: 'Enterprise',
        status: 'ACTIVO',
        branches: 4,
        users: 63,
        monthlyRevenue: 24900,
        createdAt: DateTime(2024, 2, 12),
      ),
      PlatformTenant(
        id: 'RST-MX-044',
        name: 'Restaurantes del Centro',
        plan: 'Business',
        status: 'ACTIVO',
        branches: 7,
        users: 91,
        monthlyRevenue: 18900,
        createdAt: DateTime(2024, 6, 8),
      ),
      PlatformTenant(
        id: 'MKT-MX-018',
        name: 'Mercados La Estrella',
        plan: 'Growth',
        status: 'PRUEBA',
        branches: 2,
        users: 17,
        monthlyRevenue: 7900,
        createdAt: DateTime(2025, 1, 21),
      ),
      PlatformTenant(
        id: 'CAF-MX-009',
        name: 'Café Norte',
        plan: 'Business',
        status: 'SUSPENDIDO',
        branches: 3,
        users: 28,
        monthlyRevenue: 0,
        createdAt: DateTime(2023, 11, 3),
      ),
    ];
  }
}
