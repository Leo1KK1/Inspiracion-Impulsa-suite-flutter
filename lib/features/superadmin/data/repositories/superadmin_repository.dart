import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/superadmin_models.dart';
import 'superadmin_session_store.dart';

abstract interface class SuperadminRepository {
  Future<SuperadminSession> login({
    required String email,
    required String password,
  });
  Future<SuperadminSession?> restoreSession();
  Future<void> logout();
  Future<SuperadminUser> getMe();
  Future<TenantPage> getTenants({
    int page = 1,
    int pageSize = 100,
    String? search,
    String? status,
  });
  Future<PlatformTenant> getTenant(String tenantId);
  Future<PlatformTenant> createTenant(Map<String, Object?> payload);
  Future<PlatformTenant> updateTenant(
    String tenantId,
    Map<String, Object?> payload,
  );
  Future<PlatformTenant> changeTenantStatus(String tenantId, String status);
  Future<List<TenantModule>> updateTenantModules(
    String tenantId,
    List<TenantModule> modules,
  );
  Future<OwnerAccount> createOwner(Map<String, Object?> payload);
  Future<OwnerAccount> updateOwner(
    String tenantId,
    Map<String, Object?> payload,
  );
  Future<OwnerAccount> changeOwnerStatus(String tenantId, String status);
}

class HttpSuperadminRepository implements SuperadminRepository {
  HttpSuperadminRepository(this._client, this._sessionStore);

  final DioClient _client;
  final SuperadminSessionStore _sessionStore;

  @override
  Future<SuperadminSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _requestMap(
      () => _client.dio.post<Object?>(
        '/api/v1/superadmin/auth/login',
        data: {'email': email.trim(), 'password': password},
      ),
    );
    final user = SuperadminUser.fromJson(
      (data['user']! as Map).cast<String, Object?>(),
    );
    final sessionData = (data['session']! as Map).cast<String, Object?>();
    final session = SuperadminSession(
      accessToken: data['accessToken']! as String,
      refreshToken: data['refreshToken']! as String,
      authContext: sessionData['authContext']! as String,
      sessionId: sessionData['sessionId']! as String,
      user: user,
    );
    if (!session.isSuperadmin) {
      throw const ApiException('El servidor devolvió un contexto no válido.');
    }
    _client.setAccessToken(session.accessToken);
    await _sessionStore.write(session);
    return session;
  }

  @override
  Future<SuperadminSession?> restoreSession() async {
    final stored = await _sessionStore.read();
    if (stored == null || !stored.isSuperadmin) {
      await _clearLocalSession();
      return null;
    }
    _client.setAccessToken(stored.accessToken);
    try {
      final user = await getMe();
      final restored = stored.copyWith(user: user);
      await _sessionStore.write(restored);
      return restored;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _clearLocalSession();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _requestData(
        () => _client.dio.post<Object?>('/api/v1/superadmin/auth/logout'),
      );
    } finally {
      await _clearLocalSession();
    }
  }

  @override
  Future<SuperadminUser> getMe() async {
    final data = await _requestMap(
      () => _client.dio.get<Object?>('/api/v1/superadmin/auth/me'),
    );
    return SuperadminUser.fromJson(data);
  }

  @override
  Future<TenantPage> getTenants({
    int page = 1,
    int pageSize = 100,
    String? search,
    String? status,
  }) async {
    final data = await _requestMap(
      () => _client.dio.get<Object?>(
        '/api/v1/superadmin/tenants',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (status != null && status.isNotEmpty) 'status': status,
        },
      ),
    );
    return TenantPage.fromJson(data);
  }

  @override
  Future<PlatformTenant> getTenant(String tenantId) async {
    final data = await _requestMap(
      () => _client.dio.get<Object?>('/api/v1/superadmin/tenants/$tenantId'),
    );
    return PlatformTenant.fromJson(data);
  }

  @override
  Future<PlatformTenant> createTenant(Map<String, Object?> payload) async {
    final data = await _requestMap(
      () => _client.dio.post<Object?>(
        '/api/v1/superadmin/tenants',
        data: payload,
      ),
    );
    return PlatformTenant.fromJson(data);
  }

  @override
  Future<PlatformTenant> updateTenant(
    String tenantId,
    Map<String, Object?> payload,
  ) async {
    final data = await _requestMap(
      () => _client.dio.patch<Object?>(
        '/api/v1/superadmin/tenants/$tenantId',
        data: payload,
      ),
    );
    return PlatformTenant.fromJson(data);
  }

  @override
  Future<PlatformTenant> changeTenantStatus(
    String tenantId,
    String status,
  ) async {
    final data = await _requestMap(
      () => _client.dio.patch<Object?>(
        '/api/v1/superadmin/tenants/$tenantId/status',
        data: {'status': status},
      ),
    );
    return PlatformTenant.fromJson(data);
  }

  @override
  Future<List<TenantModule>> updateTenantModules(
    String tenantId,
    List<TenantModule> modules,
  ) async {
    final data = await _requestList(
      () => _client.dio.patch<Object?>(
        '/api/v1/superadmin/tenants/$tenantId/modules',
        data: {'modules': modules.map((module) => module.toJson()).toList()},
      ),
    );
    return data
        .map(
          (item) =>
              TenantModule.fromJson((item as Map).cast<String, Object?>()),
        )
        .toList(growable: false);
  }

  @override
  Future<OwnerAccount> createOwner(Map<String, Object?> payload) async {
    final data = await _requestMap(
      () => _client.dio.post<Object?>(
        '/api/v1/superadmin/users/owners',
        data: payload,
      ),
    );
    return OwnerAccount.fromJson(data);
  }

  @override
  Future<OwnerAccount> updateOwner(
    String tenantId,
    Map<String, Object?> payload,
  ) async {
    final data = await _requestMap(
      () => _client.dio.patch<Object?>(
        '/api/v1/superadmin/tenants/$tenantId/owner',
        data: payload,
      ),
    );
    return OwnerAccount.fromJson(data);
  }

  @override
  Future<OwnerAccount> changeOwnerStatus(String tenantId, String status) async {
    final data = await _requestMap(
      () => _client.dio.patch<Object?>(
        '/api/v1/superadmin/tenants/$tenantId/owner/status',
        data: {'status': status},
      ),
    );
    return OwnerAccount.fromJson(data);
  }

  Future<void> _clearLocalSession() async {
    _client.setAccessToken(null);
    await _sessionStore.clear();
  }

  Future<Map<String, Object?>> _requestMap(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _requestData(request);
    if (data is! Map) {
      throw const ApiException('El servidor devolvió una respuesta no válida.');
    }
    return data.cast<String, Object?>();
  }

  Future<List<Object?>> _requestList(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _requestData(request);
    if (data is! List) {
      throw const ApiException('El servidor devolvió una respuesta no válida.');
    }
    return data.cast<Object?>();
  }

  Future<Object?> _requestData(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      final envelope = response.data;
      if (envelope is! Map || envelope['success'] != true) {
        throw const ApiException(
          'El servidor devolvió una respuesta no válida.',
        );
      }
      return envelope['data'];
    } on DioException catch (error) {
      final apiError = ApiException.fromDio(error);
      if (apiError.statusCode == 401 || apiError.statusCode == 403) {
        await _clearLocalSession();
      }
      throw apiError;
    }
  }
}
