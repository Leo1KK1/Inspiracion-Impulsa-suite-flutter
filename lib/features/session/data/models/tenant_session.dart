class TenantBranchAccess {
  const TenantBranchAccess({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.isPrimary = false,
  });

  final String id;
  final String name;
  final String code;
  final String status;
  final bool isPrimary;

  bool get isActive => status == 'ACTIVE';

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'status': status,
    'isPrimary': isPrimary,
  };

  factory TenantBranchAccess.fromJson(Map<String, Object?> json) {
    return TenantBranchAccess(
      id: json['id']! as String,
      name: json['name']! as String,
      code: json['code']! as String,
      status: json['status']! as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class TenantSession {
  const TenantSession({
    required this.authContext,
    required this.actorId,
    required this.actorType,
    required this.tenantId,
    required this.tenantName,
    required this.tenantSlug,
    required this.tenantStatus,
    required this.activeBranchId,
    required this.roleCodes,
    required this.permissions,
    required this.branches,
    required this.sessionId,
    required this.accessToken,
    required this.refreshToken,
    required this.userName,
    required this.userEmail,
  });

  final String authContext;
  final String actorId;
  final String actorType;
  final String tenantId;
  final String tenantName;
  final String tenantSlug;
  final String tenantStatus;
  final String? activeBranchId;
  final List<String> roleCodes;
  final List<String> permissions;
  final List<TenantBranchAccess> branches;
  final String sessionId;
  final String accessToken;
  final String refreshToken;
  final String userName;
  final String userEmail;

  String? get activeBranchName {
    for (final branch in branches) {
      if (branch.id == activeBranchId) return branch.name;
    }
    return null;
  }

  TenantSession copyWith({
    String? activeBranchId,
    List<String>? roleCodes,
    List<String>? permissions,
    List<TenantBranchAccess>? branches,
    String? sessionId,
    String? accessToken,
    String? refreshToken,
    String? userName,
    String? userEmail,
    String? tenantName,
    String? tenantSlug,
    String? tenantStatus,
  }) {
    return TenantSession(
      authContext: authContext,
      actorId: actorId,
      actorType: actorType,
      tenantId: tenantId,
      tenantName: tenantName ?? this.tenantName,
      tenantSlug: tenantSlug ?? this.tenantSlug,
      tenantStatus: tenantStatus ?? this.tenantStatus,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      roleCodes: roleCodes ?? this.roleCodes,
      permissions: permissions ?? this.permissions,
      branches: branches ?? this.branches,
      sessionId: sessionId ?? this.sessionId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  Map<String, Object?> toJson() => {
    'authContext': authContext,
    'actorId': actorId,
    'actorType': actorType,
    'tenantId': tenantId,
    'tenantName': tenantName,
    'tenantSlug': tenantSlug,
    'tenantStatus': tenantStatus,
    'activeBranchId': activeBranchId,
    'roleCodes': roleCodes,
    'permissions': permissions,
    'branches': branches.map((branch) => branch.toJson()).toList(),
    'sessionId': sessionId,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'userName': userName,
    'userEmail': userEmail,
  };

  factory TenantSession.fromJson(Map<String, Object?> json) {
    return TenantSession(
      authContext: json['authContext']! as String,
      actorId: json['actorId']! as String,
      actorType: json['actorType']! as String,
      tenantId: json['tenantId']! as String,
      tenantName: json['tenantName']! as String,
      tenantSlug: json['tenantSlug']! as String,
      tenantStatus: json['tenantStatus']! as String,
      activeBranchId: json['activeBranchId'] as String?,
      roleCodes: (json['roleCodes']! as List).cast<String>(),
      permissions: (json['permissions']! as List).cast<String>(),
      branches: (json['branches']! as List)
          .map(
            (branch) => TenantBranchAccess.fromJson(
              (branch as Map).cast<String, Object?>(),
            ),
          )
          .toList(growable: false),
      sessionId: json['sessionId']! as String,
      accessToken: json['accessToken']! as String,
      refreshToken: json['refreshToken']! as String,
      userName: json['userName']! as String,
      userEmail: json['userEmail']! as String,
    );
  }
}
