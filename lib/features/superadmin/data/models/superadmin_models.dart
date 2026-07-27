class PlatformTenant {
  const PlatformTenant({
    required this.id,
    required this.name,
    required this.plan,
    required this.status,
    required this.branches,
    required this.users,
    required this.monthlyRevenue,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String plan;
  final String status;
  final int branches;
  final int users;
  final double monthlyRevenue;
  final DateTime createdAt;

  PlatformTenant copyWith({String? status}) => PlatformTenant(
    id: id,
    name: name,
    plan: plan,
    status: status ?? this.status,
    branches: branches,
    users: users,
    monthlyRevenue: monthlyRevenue,
    createdAt: createdAt,
  );
}
