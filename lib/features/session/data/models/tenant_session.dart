class TenantSession {
  const TenantSession({
    required this.authContext,
    required this.actorId,
    required this.actorType,
    required this.tenantId,
    required this.tenantName,
    required this.activeBranchId,
    required this.activeBranchName,
    required this.roleCodes,
    required this.sessionId,
    required this.accessToken,
    this.refreshToken,
    required this.userName,
    required this.userEmail,
  });

  final String authContext;
  final String actorId;
  final String actorType;
  final String tenantId;
  final String tenantName;
  final String? activeBranchId;
  final String? activeBranchName;
  final List<String> roleCodes;
  final String sessionId;
  final String accessToken;
  final String? refreshToken;
  final String userName;
  final String userEmail;

  TenantSession copyWith({
    String? activeBranchId,
    String? activeBranchName,
    List<String>? roleCodes,
  }) {
    return TenantSession(
      authContext: authContext,
      actorId: actorId,
      actorType: actorType,
      tenantId: tenantId,
      tenantName: tenantName,
      activeBranchId: activeBranchId ?? this.activeBranchId,
      activeBranchName: activeBranchName ?? this.activeBranchName,
      roleCodes: roleCodes ?? this.roleCodes,
      sessionId: sessionId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userName: userName,
      userEmail: userEmail,
    );
  }

  Map<String, Object?> toJson() => {
    'authContext': authContext,
    'actorId': actorId,
    'actorType': actorType,
    'tenantId': tenantId,
    'tenantName': tenantName,
    'activeBranchId': activeBranchId,
    'activeBranchName': activeBranchName,
    'roleCodes': roleCodes,
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
      activeBranchId: json['activeBranchId'] as String?,
      activeBranchName: json['activeBranchName'] as String?,
      roleCodes: (json['roleCodes']! as List).cast<String>(),
      sessionId: json['sessionId']! as String,
      accessToken: json['accessToken']! as String,
      refreshToken: json['refreshToken'] as String?,
      userName: json['userName']! as String,
      userEmail: json['userEmail']! as String,
    );
  }
}
