import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/tenant_session.dart';

abstract interface class SessionRepository {
  Future<TenantSession?> restore();
  Future<TenantSession> login({
    required String tenantSlug,
    required String email,
    required String password,
  });
  Future<TenantSession> switchBranch(String branchId);
  Future<void> logout();
  void setSessionListener(void Function(TenantSession? session) listener);
}

abstract interface class TenantSessionStore {
  Future<TenantSession?> read();
  Future<void> write(TenantSession session);
  Future<void> clear();
}

class PreferencesTenantSessionStore implements TenantSessionStore {
  static const _key = 'tenant_session';

  @override
  Future<TenantSession?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      return TenantSession.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      await preferences.remove(_key);
      return null;
    }
  }

  @override
  Future<void> write(TenantSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}

class HttpTenantSessionRepository implements SessionRepository {
  HttpTenantSessionRepository(this._client, this._store) {
    _client.dio.interceptors.add(
      InterceptorsWrapper(onError: _handleUnauthorized),
    );
  }

  static const _authBase = '/api/v1/tenant/auth';
  static const _retriedKey = 'tenantRefreshRetried';

  final DioClient _client;
  final TenantSessionStore _store;
  TenantSession? _current;
  Future<bool>? _refreshInFlight;
  void Function(TenantSession? session)? _listener;

  @override
  void setSessionListener(void Function(TenantSession? session) listener) {
    _listener = listener;
  }

  @override
  Future<TenantSession?> restore() async {
    final stored = await _store.read();
    if (stored == null || stored.authContext != 'tenant') {
      await _clearLocal();
      return null;
    }
    _current = stored;
    _client.setAccessToken(stored.accessToken);
    try {
      final me = await _requestMap(
        () => _client.dio.get<Object?>('$_authBase/me'),
      );
      final restored = _fromMe(stored, me);
      await _setCurrent(restored);
      return restored;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _clearLocal();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<TenantSession> login({
    required String tenantSlug,
    required String email,
    required String password,
  }) async {
    final data = await _requestMap(
      () => _client.dio.post<Object?>(
        '$_authBase/login',
        data: {
          'tenantSlug': tenantSlug.trim(),
          'email': email.trim(),
          'password': password,
        },
      ),
    );
    final session = _fromLogin(data);
    await _setCurrent(session);
    return session;
  }

  @override
  Future<TenantSession> switchBranch(String branchId) async {
    final current = _current;
    if (current == null) {
      throw const ApiException('No existe una sesión activa.', statusCode: 401);
    }
    final data = await _requestMap(
      () => _client.dio.post<Object?>(
        '$_authBase/switch-branch',
        data: {'branchId': branchId},
      ),
    );
    final sessionData = _map(data['session']);
    final updated = current.copyWith(
      activeBranchId: sessionData['activeBranchId'] as String?,
      sessionId: sessionData['sessionId'] as String?,
      accessToken: data['accessToken'] as String?,
      refreshToken: data['refreshToken'] as String?,
      permissions: _strings(data['permissions']),
    );
    await _setCurrent(updated);
    return updated;
  }

  @override
  Future<void> logout() async {
    try {
      await _requestData(() => _client.dio.post<Object?>('$_authBase/logout'));
    } finally {
      await _clearLocal();
    }
  }

  Future<void> _handleUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final canRefresh =
        error.response?.statusCode == 401 &&
        request.extra[_retriedKey] != true &&
        !request.path.endsWith('/login') &&
        !request.path.endsWith('/refresh') &&
        _current?.refreshToken.isNotEmpty == true;
    if (!canRefresh || !await _refreshOnce()) {
      handler.next(error);
      return;
    }
    try {
      final options = request;
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer ${_current!.accessToken}';
      handler.resolve(await _client.dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshOnce() {
    final running = _refreshInFlight;
    if (running != null) return running;
    final future = _performRefresh();
    _refreshInFlight = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_refreshInFlight, future)) _refreshInFlight = null;
      }),
    );
    return future;
  }

  Future<bool> _performRefresh() async {
    final current = _current;
    if (current == null || current.refreshToken.isEmpty) return false;
    try {
      final response = await _client.dio.post<Object?>(
        '$_authBase/refresh',
        data: {'refreshToken': current.refreshToken},
        options: Options(extra: {_retriedKey: true}),
      );
      final data = _unwrapMap(response.data);
      final sessionData = _map(data['session']);
      await _setCurrent(
        current.copyWith(
          activeBranchId: sessionData['activeBranchId'] as String?,
          sessionId: sessionData['sessionId'] as String?,
          accessToken: data['accessToken'] as String?,
          refreshToken: data['refreshToken'] as String?,
        ),
      );
      return true;
    } on Object {
      await _clearLocal();
      return false;
    }
  }

  TenantSession _fromLogin(Map<String, Object?> data) {
    final user = _map(data['user']);
    final tenant = _map(data['tenant']);
    final session = _map(data['session']);
    return TenantSession(
      authContext: session['authContext']! as String,
      actorId: user['id']! as String,
      actorType: 'TENANT_USER',
      tenantId: tenant['id']! as String,
      tenantName: tenant['name']! as String,
      tenantSlug: tenant['slug']! as String,
      tenantStatus: tenant['status']! as String,
      activeBranchId: session['activeBranchId'] as String?,
      roleCodes: _strings(user['roleCodes']),
      permissions: _strings(data['permissions']),
      branches: _branches(data['branches']),
      sessionId: session['sessionId']! as String,
      accessToken: data['accessToken']! as String,
      refreshToken: data['refreshToken']! as String,
      userName: user['fullName']! as String,
      userEmail: user['email']! as String,
    );
  }

  TenantSession _fromMe(TenantSession stored, Map<String, Object?> data) {
    final tenant = _map(data['tenant']);
    final session = _map(data['session']);
    return stored.copyWith(
      activeBranchId: session['activeBranchId'] as String?,
      userName: data['fullName'] as String?,
      userEmail: data['email'] as String?,
      roleCodes: _strings(data['roleCodes']),
      permissions: _strings(data['permissions']),
      branches: _branches(data['branches']),
      tenantName: tenant['name'] as String?,
      tenantSlug: tenant['slug'] as String?,
      tenantStatus: tenant['status'] as String?,
    );
  }

  Future<void> _setCurrent(TenantSession session) async {
    _current = session;
    _client.setAccessToken(session.accessToken);
    await _store.write(session);
    _listener?.call(session);
  }

  Future<void> _clearLocal() async {
    _current = null;
    _client.setAccessToken(null);
    await _store.clear();
    _listener?.call(null);
  }

  Future<Map<String, Object?>> _requestMap(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      return _unwrapMap(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
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
      throw ApiException.fromDio(error);
    }
  }

  Map<String, Object?> _unwrapMap(Object? envelope) {
    if (envelope is! Map || envelope['success'] != true) {
      throw const ApiException('El servidor devolvió una respuesta no válida.');
    }
    return _map(envelope['data']);
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) {
      throw const ApiException('El servidor devolvió una respuesta no válida.');
    }
    return value.cast<String, Object?>();
  }

  static List<String> _strings(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  static List<TenantBranchAccess> _branches(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (branch) =>
              TenantBranchAccess.fromJson(branch.cast<String, Object?>()),
        )
        .toList(growable: false);
  }
}
