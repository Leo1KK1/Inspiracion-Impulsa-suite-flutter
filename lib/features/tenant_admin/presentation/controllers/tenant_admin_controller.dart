import 'package:flutter/foundation.dart';

import '../../data/models/tenant_admin_models.dart';
import '../../data/repositories/tenant_admin_repository.dart';

enum TenantAdminStatus { idle, loading, success, empty, error }

class TenantAdminController extends ChangeNotifier {
  TenantAdminController(this._repository);
  final TenantAdminRepository _repository;

  TenantAdminStatus status = TenantAdminStatus.idle;
  List<Branch> branches = const [];
  List<TenantEmployee> employees = const [];
  List<TenantRole> roles = const [];
  String? errorMessage;

  Future<void> load() async {
    if (status == TenantAdminStatus.loading) return;
    status = TenantAdminStatus.loading;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getBranches(),
        _repository.getEmployees(),
        _repository.getRoles(),
      ]);
      branches = results[0] as List<Branch>;
      employees = results[1] as List<TenantEmployee>;
      roles = results[2] as List<TenantRole>;
      status = branches.isEmpty
          ? TenantAdminStatus.empty
          : TenantAdminStatus.success;
    } on Object {
      errorMessage = 'No fue posible cargar la administración del tenant.';
      status = TenantAdminStatus.error;
    }
    notifyListeners();
  }

  void addBranch(Branch branch) {
    branches = [...branches, branch];
    notifyListeners();
  }

  void addEmployee(TenantEmployee employee) {
    employees = [...employees, employee];
    notifyListeners();
  }
}
