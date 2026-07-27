import '../models/tenant_admin_models.dart';

abstract interface class TenantAdminRepository {
  Future<List<Branch>> getBranches();
  Future<List<TenantEmployee>> getEmployees();
  Future<List<TenantRole>> getRoles();
}

class MockTenantAdminRepository implements TenantAdminRepository {
  @override
  Future<List<Branch>> getBranches() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return const [
      Branch(
        id: 'CDMX-01',
        name: 'Sucursal CDMX Centro',
        city: 'Ciudad de México',
        address: 'Av. Reforma 245, Cuauhtémoc',
        status: 'ACTIVA',
        salesToday: 55240,
        employees: 24,
      ),
      Branch(
        id: 'CDMX-02',
        name: 'Sucursal Polanco',
        city: 'Ciudad de México',
        address: 'Masaryk 188, Polanco',
        status: 'ACTIVA',
        salesToday: 48710,
        employees: 18,
      ),
      Branch(
        id: 'GDL-01',
        name: 'Sucursal Guadalajara',
        city: 'Guadalajara',
        address: 'Av. Vallarta 1420',
        status: 'ACTIVA',
        salesToday: 39580,
        employees: 19,
      ),
      Branch(
        id: 'MTY-01',
        name: 'Sucursal Monterrey',
        city: 'Monterrey',
        address: 'Calzada del Valle 410',
        status: 'MANTENIMIENTO',
        salesToday: 0,
        employees: 12,
      ),
    ];
  }

  @override
  Future<List<TenantEmployee>> getEmployees() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return const [
      TenantEmployee(
        id: 'USR-104',
        name: 'María López',
        email: 'm.lopez@grupovega.mx',
        role: 'BRANCH_MANAGER',
        branchIds: ['CDMX-01', 'CDMX-02'],
        active: true,
      ),
      TenantEmployee(
        id: 'USR-118',
        name: 'Carlos Méndez',
        email: 'c.mendez@grupovega.mx',
        role: 'CASHIER',
        branchIds: ['CDMX-01'],
        active: true,
      ),
      TenantEmployee(
        id: 'USR-126',
        name: 'Sofía Reyes',
        email: 's.reyes@grupovega.mx',
        role: 'WAITER',
        branchIds: ['CDMX-01'],
        active: true,
      ),
      TenantEmployee(
        id: 'USR-139',
        name: 'Diego Flores',
        email: 'd.flores@grupovega.mx',
        role: 'INVENTORY_CLERK',
        branchIds: ['GDL-01'],
        active: false,
      ),
    ];
  }

  @override
  Future<List<TenantRole>> getRoles() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [
      TenantRole(
        code: 'OWNER',
        name: 'Propietario',
        description: 'Acceso total al tenant y todas sus sucursales.',
        permissions: ['Administración', 'Finanzas', 'Operación', 'Reportes'],
        users: 2,
      ),
      TenantRole(
        code: 'BRANCH_MANAGER',
        name: 'Gerente de sucursal',
        description: 'Administra operación y personal de sucursales asignadas.',
        permissions: ['Inventario', 'Compras', 'POS', 'Restaurante'],
        users: 8,
      ),
      TenantRole(
        code: 'CASHIER',
        name: 'Cajero',
        description: 'Opera POS, turnos, pagos y tickets.',
        permissions: ['POS', 'Turnos', 'Tickets'],
        users: 14,
      ),
      TenantRole(
        code: 'WAITER',
        name: 'Mesero',
        description: 'Gestiona mesas, comandas y división de cuenta.',
        permissions: ['Mesas', 'Comandas'],
        users: 21,
      ),
    ];
  }
}
