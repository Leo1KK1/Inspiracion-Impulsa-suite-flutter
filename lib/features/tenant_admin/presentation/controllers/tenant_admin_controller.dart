import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/tenant_admin_models.dart';
import '../../data/repositories/tenant_admin_repository.dart';

enum TenantAdminStatus { idle, loading, success, empty, error }

class TenantAdminController extends ChangeNotifier {
  TenantAdminController(this._repository);

  final TenantAdminRepository _repository;
  TenantAdminStatus status = TenantAdminStatus.idle;
  TenantDashboardMetrics? dashboard;
  List<Branch> branches = const [];
  List<TenantEmployee> employees = const [];
  List<TenantRole> roles = const [];
  List<BranchStaffGroup> branchStaff = const [];
  String? errorMessage;
  bool saving = false;

  Future<void> load({bool force = false}) async {
    if (status == TenantAdminStatus.loading || (!force && dashboard != null)) {
      return;
    }
    status = TenantAdminStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getDashboard(),
        _repository.getBranches(),
        _repository.getEmployees(),
        _repository.getRoles(),
        _repository.getBranchesWithEmployees(),
      ]);
      dashboard = results[0] as TenantDashboardMetrics;
      branches = results[1] as List<Branch>;
      employees = results[2] as List<TenantEmployee>;
      roles = results[3] as List<TenantRole>;
      branchStaff = results[4] as List<BranchStaffGroup>;
      status = branches.isEmpty
          ? TenantAdminStatus.empty
          : TenantAdminStatus.success;
    } on ApiException catch (error) {
      errorMessage = error.message;
      status = TenantAdminStatus.error;
    } on Object {
      errorMessage = 'No fue posible cargar la administración del tenant.';
      status = TenantAdminStatus.error;
    }
    notifyListeners();
  }

  Future<bool> createBranch(Map<String, Object?> payload) =>
      _mutate(() => _repository.createBranch(payload));

  Future<bool> updateBranch(String id, Map<String, Object?> payload) =>
      _mutate(() => _repository.updateBranch(id, payload));

  Future<bool> changeBranchStatus(String id, String status) =>
      _mutate(() => _repository.changeBranchStatus(id, status));

  Future<bool> createEmployee(Map<String, Object?> payload) =>
      _mutate(() => _repository.createEmployee(payload));

  Future<bool> updateEmployee(String id, Map<String, Object?> payload) =>
      _mutate(() => _repository.updateEmployee(id, payload));

  Future<bool> changeEmployeeStatus(String id, String status) =>
      _mutate(() => _repository.changeEmployeeStatus(id, status));

  Future<bool> createRole(Map<String, Object?> payload) async {
    if (saving) return false;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final created = await _repository.createRole(payload);
      roles = [...roles, created];
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } on Object {
      errorMessage = 'No fue posible crear el rol.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void invalidate() {
    dashboard = null;
    branches = const [];
    employees = const [];
    roles = const [];
    branchStaff = const [];
    status = TenantAdminStatus.idle;
    notifyListeners();
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (saving) return false;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      saving = false;
      await load(force: true);
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible completar la operación.';
    }
    saving = false;
    notifyListeners();
    return false;
  }
}
