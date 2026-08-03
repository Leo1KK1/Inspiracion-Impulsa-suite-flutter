import '../features/session/presentation/controllers/tenant_session_controller.dart';

abstract final class TenantGuard {
  static String? redirect(TenantSessionController session, String location) {
    if (!session.isAuthenticated) {
      return '/tenant-login?from=${Uri.encodeComponent(location)}';
    }
    if (!session.isTenant) return '/app/access-denied';
    if (session.session?.tenantStatus != 'ACTIVE') {
      return '/app/tenant-suspended';
    }
    return null;
  }
}

abstract final class BranchContextGuard {
  static String? redirect(TenantSessionController session) {
    if (session.activeBranchId == null) return '/app/branch-context';
    return null;
  }
}

abstract final class RoleGuard {
  static String? redirect(
    TenantSessionController session,
    Iterable<String> roles,
  ) {
    return session.hasAnyRole(roles) ? null : '/app/access-denied';
  }
}

abstract final class AdminRoleGuard {
  static const roles = ['OWNER', 'MANAGER'];

  static String? redirect(TenantSessionController session) =>
      RoleGuard.redirect(session, roles);
}

abstract final class WaiterRoleGuard {
  static const roles = ['WAITER', 'CASHIER', 'MANAGER', 'OWNER'];

  static String? redirect(TenantSessionController session) =>
      RoleGuard.redirect(session, roles);
}

abstract final class KitchenRoleGuard {
  static const roles = ['CHEF', 'WAITER', 'MANAGER', 'OWNER'];

  static String? redirect(TenantSessionController session) =>
      RoleGuard.redirect(session, roles);
}

abstract final class PosRoleGuard {
  static const roles = ['CASHIER', 'MANAGER', 'OWNER'];

  static String? redirect(TenantSessionController session) =>
      RoleGuard.redirect(session, roles);
}
