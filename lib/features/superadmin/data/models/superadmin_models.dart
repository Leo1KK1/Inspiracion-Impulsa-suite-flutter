class SuperadminUser {
  const SuperadminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roleCodes,
    this.status,
  });

  final String id;
  final String fullName;
  final String email;
  final List<String> roleCodes;
  final String? status;

  factory SuperadminUser.fromJson(Map<String, Object?> json) => SuperadminUser(
    id: json['id']! as String,
    fullName: json['fullName']! as String,
    email: json['email']! as String,
    roleCodes: (json['roleCodes'] as List? ?? const []).cast<String>(),
    status: json['status'] as String?,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'roleCodes': roleCodes,
    'status': status,
  };
}

class SuperadminSession {
  const SuperadminSession({
    required this.accessToken,
    required this.refreshToken,
    required this.authContext,
    required this.sessionId,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String authContext;
  final String sessionId;
  final SuperadminUser user;

  bool get isSuperadmin => authContext.toLowerCase() == 'superadmin';

  SuperadminSession copyWith({SuperadminUser? user}) => SuperadminSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    authContext: authContext,
    sessionId: sessionId,
    user: user ?? this.user,
  );

  factory SuperadminSession.fromJson(Map<String, Object?> json) =>
      SuperadminSession(
        accessToken: json['accessToken']! as String,
        refreshToken: json['refreshToken']! as String,
        authContext: json['authContext']! as String,
        sessionId: json['sessionId']! as String,
        user: SuperadminUser.fromJson(
          (json['user']! as Map).cast<String, Object?>(),
        ),
      );

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'authContext': authContext,
    'sessionId': sessionId,
    'user': user.toJson(),
  };
}

class TenantSubscription {
  const TenantSubscription({required this.planCode, required this.status});

  final String planCode;
  final String status;

  factory TenantSubscription.fromJson(Map<String, Object?> json) =>
      TenantSubscription(
        planCode: json['planCode']! as String,
        status: json['status']! as String,
      );
}

class TenantModule {
  const TenantModule({required this.moduleCode, required this.isEnabled});

  final String moduleCode;
  final bool isEnabled;

  factory TenantModule.fromJson(Map<String, Object?> json) => TenantModule(
    moduleCode: json['moduleCode']! as String,
    isEnabled: json['isEnabled']! as bool,
  );

  Map<String, Object?> toJson() => {
    'moduleCode': moduleCode,
    'isEnabled': isEnabled,
  };
}

class TenantBranch {
  const TenantBranch({
    required this.id,
    required this.name,
    required this.code,
    this.status,
    this.address,
  });

  final String id;
  final String name;
  final String code;
  final String? status;
  final String? address;

  factory TenantBranch.fromJson(Map<String, Object?> json) => TenantBranch(
    id: json['id']! as String,
    name: json['name']! as String,
    code: json['code']! as String,
    status: json['status'] as String?,
    address: json['address'] as String?,
  );
}

class PlatformTenant {
  const PlatformTenant({
    required this.id,
    required this.name,
    required this.slug,
    required this.primaryEmail,
    required this.status,
    required this.subscriptions,
    required this.modules,
    required this.branches,
    this.address,
  });

  final String id;
  final String name;
  final String slug;
  final String primaryEmail;
  final String? address;
  final String status;
  final List<TenantSubscription> subscriptions;
  final List<TenantModule> modules;
  final List<TenantBranch> branches;

  String get planCode =>
      subscriptions.isEmpty ? 'Sin plan' : subscriptions.first.planCode;
  int get enabledModuleCount =>
      modules.where((module) => module.isEnabled).length;

  factory PlatformTenant.fromJson(Map<String, Object?> json) => PlatformTenant(
    id: json['id']! as String,
    name: json['name']! as String,
    slug: json['slug']! as String,
    primaryEmail: json['primaryEmail']! as String,
    address: json['address'] as String?,
    status: json['status']! as String,
    subscriptions: _mapList(json['subscriptions'], TenantSubscription.fromJson),
    modules: _mapList(json['modules'], TenantModule.fromJson),
    branches: _mapList(json['branches'], TenantBranch.fromJson),
  );
}

class TenantPage {
  const TenantPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<PlatformTenant> items;
  final int total;
  final int page;
  final int pageSize;

  factory TenantPage.fromJson(Map<String, Object?> json) => TenantPage(
    items: _mapList(json['items'], PlatformTenant.fromJson),
    total: (json['total'] as num).toInt(),
    page: (json['page'] as num).toInt(),
    pageSize: (json['pageSize'] as num).toInt(),
  );
}

class OwnerAccount {
  const OwnerAccount({
    required this.id,
    required this.tenantId,
    required this.fullName,
    required this.email,
    required this.status,
    this.primaryBranch,
  });

  final String id;
  final String tenantId;
  final String fullName;
  final String email;
  final String status;
  final TenantBranch? primaryBranch;

  factory OwnerAccount.fromJson(Map<String, Object?> json) {
    final branch = json['primaryBranch'];
    return OwnerAccount(
      id: json['id']! as String,
      tenantId: json['tenantId']! as String,
      fullName: json['fullName']! as String,
      email: json['email']! as String,
      status: json['status']! as String,
      primaryBranch: branch is Map
          ? TenantBranch(
              id: branch['id']! as String,
              name: branch['name']! as String,
              code: branch['code']! as String,
            )
          : null,
    );
  }
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, Object?> json) factory,
) => (value as List? ?? const [])
    .map((item) => factory((item as Map).cast<String, Object?>()))
    .toList(growable: false);
