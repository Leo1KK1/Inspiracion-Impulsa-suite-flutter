class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.status,
    required this.salesToday,
    required this.employees,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String status;
  final double salesToday;
  final int employees;
}

class TenantEmployee {
  const TenantEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.branchIds,
    required this.active,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> branchIds;
  final bool active;
}

class TenantRole {
  const TenantRole({
    required this.code,
    required this.name,
    required this.description,
    required this.permissions,
    required this.users,
  });

  final String code;
  final String name;
  final String description;
  final List<String> permissions;
  final int users;
}
