class TenantDashboardMetrics {
  const TenantDashboardMetrics({
    required this.totalBranches,
    required this.activeBranches,
    required this.totalEmployees,
    required this.activeEmployees,
    required this.totalRoles,
  });

  final int totalBranches;
  final int activeBranches;
  final int totalEmployees;
  final int activeEmployees;
  final int totalRoles;

  factory TenantDashboardMetrics.fromJson(Map<String, Object?> json) {
    return TenantDashboardMetrics(
      totalBranches: (json['totalBranches'] as num?)?.toInt() ?? 0,
      activeBranches: (json['activeBranches'] as num?)?.toInt() ?? 0,
      totalEmployees: (json['totalEmployees'] as num?)?.toInt() ?? 0,
      activeEmployees: (json['activeEmployees'] as num?)?.toInt() ?? 0,
      totalRoles: (json['totalRoles'] as num?)?.toInt() ?? 0,
    );
  }
}

class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.address,
    this.employeeCount = 0,
  });

  final String id;
  final String name;
  final String code;
  final String status;
  final String? address;
  final int employeeCount;

  bool get isActive => status == 'ACTIVE';

  Branch copyWith({int? employeeCount}) => Branch(
    id: id,
    name: name,
    code: code,
    status: status,
    address: address,
    employeeCount: employeeCount ?? this.employeeCount,
  );

  factory Branch.fromJson(Map<String, Object?> json) => Branch(
    id: json['id']! as String,
    name: json['name']! as String,
    code: json['code']! as String,
    status: json['status']! as String,
    address: json['address'] as String?,
    employeeCount: (json['employeeCount'] as num?)?.toInt() ?? 0,
  );
}

class TenantEmployee {
  const TenantEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.roleCode,
    this.roleName,
    this.branchId,
    this.branchName,
  });

  final String id;
  final String name;
  final String email;
  final String status;
  final String? roleCode;
  final String? roleName;
  final String? branchId;
  final String? branchName;

  bool get active => status == 'ACTIVE';

  factory TenantEmployee.fromJson(Map<String, Object?> json) {
    final role = _nullableMap(json['role']);
    final branch = _nullableMap(json['assignedBranch']);
    return TenantEmployee(
      id: json['id']! as String,
      name: (json['fullName'] ?? json['name'])! as String,
      email: json['email']! as String,
      status: json['status']! as String,
      roleCode: role?['code'] as String? ?? json['roleCode'] as String?,
      roleName: role?['name'] as String?,
      branchId: branch?['id'] as String?,
      branchName: branch?['name'] as String?,
    );
  }
}

class TenantRole {
  const TenantRole({
    required this.code,
    required this.name,
    required this.description,
    required this.permissions,
    this.scope,
    this.isSystem,
  });

  final String code;
  final String name;
  final String description;
  final List<String> permissions;
  final String? scope;
  final bool? isSystem;

  factory TenantRole.fromJson(Map<String, Object?> json) {
    final rawPermissions =
        json['permissions'] ?? json['linkedPermissions'] ?? const [];
    return TenantRole(
      code: json['code']! as String,
      name: json['name']! as String,
      description: json['description'] as String? ?? '',
      permissions: rawPermissions is List
          ? rawPermissions
                .map((permission) {
                  if (permission is String) return permission;
                  if (permission is Map) {
                    return (permission['code'] ?? permission['name'])
                        as String?;
                  }
                  return null;
                })
                .whereType<String>()
                .toList(growable: false)
          : const [],
      scope: json['scope'] as String?,
      isSystem: json['isSystem'] as bool?,
    );
  }
}

class BranchStaffGroup {
  const BranchStaffGroup({
    required this.branch,
    required this.managers,
    required this.employees,
  });

  final Branch branch;
  final List<TenantEmployee> managers;
  final List<TenantEmployee> employees;

  factory BranchStaffGroup.fromJson(Map<String, Object?> json) {
    List<TenantEmployee> people(Object? value) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((raw) {
            final item = raw.cast<String, Object?>();
            final role = _nullableMap(item['role']);
            return TenantEmployee(
              id: item['id']! as String,
              name: item['fullName']! as String,
              email: item['email']! as String,
              status: item['status']! as String,
              roleCode: role?['code'] as String?,
              roleName: role?['name'] as String?,
              branchId: json['id'] as String?,
              branchName: json['name'] as String?,
            );
          })
          .toList(growable: false);
    }

    return BranchStaffGroup(
      branch: Branch.fromJson(json),
      managers: people(json['managers']),
      employees: people(json['employees']),
    );
  }
}

Map<String, Object?>? _nullableMap(Object? value) =>
    value is Map ? value.cast<String, Object?>() : null;
