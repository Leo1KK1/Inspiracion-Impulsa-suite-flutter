import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/tenant_admin_models.dart';

abstract interface class TenantAdminRepository {
  Future<TenantDashboardMetrics> getDashboard();
  Future<List<Branch>> getBranches();
  Future<List<TenantEmployee>> getEmployees();
  Future<List<TenantRole>> getRoles();
  Future<List<BranchStaffGroup>> getBranchesWithEmployees();
  Future<void> createBranch(Map<String, Object?> payload);
  Future<void> updateBranch(String id, Map<String, Object?> payload);
  Future<void> changeBranchStatus(String id, String status);
  Future<void> createEmployee(Map<String, Object?> payload);
  Future<void> updateEmployee(String id, Map<String, Object?> payload);
  Future<void> changeEmployeeStatus(String id, String status);
  Future<TenantRole> createRole(Map<String, Object?> payload);
}

class HttpTenantAdminRepository implements TenantAdminRepository {
  HttpTenantAdminRepository(this._client);

  final DioClient _client;

  @override
  Future<TenantDashboardMetrics> getDashboard() async =>
      TenantDashboardMetrics.fromJson(
        await _requestMap(
          () => _client.dio.get<Object?>('/api/v1/tenant/dashboard'),
        ),
      );

  @override
  Future<List<Branch>> getBranches() async {
    final results = await Future.wait([
      _requestList(
        () => _client.dio.get<Object?>('/api/v1/tenant/branches'),
      ),
      _requestList(
        () => _client.dio.get<Object?>(
          '/api/v1/tenant/branches/employee-count',
        ),
      ),
    ]);
    final counts = <String, int>{
      for (final raw in results[1].whereType<Map>())
        if (raw['branchId'] is String)
          raw['branchId']! as String:
              (raw['employeeCount'] as num?)?.toInt() ?? 0,
    };
    return results[0]
        .whereType<Map>()
        .map((raw) {
          final branch = Branch.fromJson(raw.cast<String, Object?>());
          return branch.copyWith(employeeCount: counts[branch.id] ?? 0);
        })
        .toList(growable: false);
  }

  @override
  Future<List<TenantEmployee>> getEmployees() async {
    final data = await _requestList(
      () => _client.dio.get<Object?>('/api/v1/tenant/users'),
    );
    return data
        .whereType<Map>()
        .map(
          (raw) => TenantEmployee.fromJson(raw.cast<String, Object?>()),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TenantRole>> getRoles() async {
    final data = await _requestList(
      () => _client.dio.get<Object?>('/api/v1/tenant/roles'),
    );
    return data
        .whereType<Map>()
        .map((raw) => TenantRole.fromJson(raw.cast<String, Object?>()))
        .toList(growable: false);
  }

  @override
  Future<List<BranchStaffGroup>> getBranchesWithEmployees() async {
    final data = await _requestList(
      () => _client.dio.get<Object?>(
        '/api/v1/tenant/branches/with-employees',
      ),
    );
    return data
        .whereType<Map>()
        .map(
          (raw) => BranchStaffGroup.fromJson(raw.cast<String, Object?>()),
        )
        .toList(growable: false);
  }

  @override
  Future<void> createBranch(Map<String, Object?> payload) => _requestVoid(
    () => _client.dio.post<Object?>(
      '/api/v1/tenant/branches',
      data: payload,
    ),
  );

  @override
  Future<void> updateBranch(String id, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.patch<Object?>(
          '/api/v1/tenant/branches/$id',
          data: payload,
        ),
      );

  @override
  Future<void> changeBranchStatus(String id, String status) => _requestVoid(
    () => _client.dio.patch<Object?>(
      '/api/v1/tenant/branches/$id/status',
      data: {'status': status},
    ),
  );

  @override
  Future<void> createEmployee(Map<String, Object?> payload) => _requestVoid(
    () => _client.dio.post<Object?>('/api/v1/tenant/users', data: payload),
  );

  @override
  Future<void> updateEmployee(String id, Map<String, Object?> payload) =>
      _requestVoid(
        () => _client.dio.patch<Object?>(
          '/api/v1/tenant/users/$id',
          data: payload,
        ),
      );

  @override
  Future<void> changeEmployeeStatus(String id, String status) => _requestVoid(
    () => _client.dio.patch<Object?>(
      '/api/v1/tenant/users/$id/status',
      data: {'status': status},
    ),
  );

  @override
  Future<TenantRole> createRole(Map<String, Object?> payload) async =>
      TenantRole.fromJson(
        await _requestMap(
          () => _client.dio.post<Object?>(
            '/api/v1/tenant/roles',
            data: payload,
          ),
        ),
      );

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

  Future<void> _requestVoid(
    Future<Response<Object?>> Function() request,
  ) async {
    await _requestData(request);
  }

  Future<Object?> _requestData(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      final envelope = response.data;
      if (envelope is! Map || envelope['success'] != true) {
        throw const ApiException('El servidor devolvió una respuesta no válida.');
      }
      return envelope['data'];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
