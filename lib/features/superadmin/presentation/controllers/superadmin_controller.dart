import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/superadmin_models.dart';
import '../../data/repositories/superadmin_repository.dart';

enum SuperadminSessionStatus { restoring, signedOut, authenticated, failure }

class SuperadminController extends ChangeNotifier {
  SuperadminController(this._repository);

  final SuperadminRepository _repository;

  SuperadminSessionStatus sessionStatus = SuperadminSessionStatus.restoring;
  SuperadminSession? session;
  bool loading = false;
  bool saving = false;
  String? errorMessage;
  TenantPage tenantPage = const TenantPage(
    items: [],
    total: 0,
    page: 1,
    pageSize: 100,
  );
  PlatformTenant? selectedTenant;
  final Map<String, OwnerAccount> ownersByTenant = {};
  String search = '';
  String? statusFilter;

  bool get isAuthenticated =>
      sessionStatus == SuperadminSessionStatus.authenticated &&
      session?.isSuperadmin == true;
  List<PlatformTenant> get tenants => tenantPage.items;
  SuperadminUser? get currentUser => session?.user;

  Future<void> restore() async {
    sessionStatus = SuperadminSessionStatus.restoring;
    notifyListeners();
    try {
      session = await _repository.restoreSession();
      sessionStatus = session == null
          ? SuperadminSessionStatus.signedOut
          : SuperadminSessionStatus.authenticated;
    } on ApiException catch (error) {
      errorMessage = error.message;
      sessionStatus = SuperadminSessionStatus.failure;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      session = await _repository.login(email: email, password: password);
      sessionStatus = SuperadminSessionStatus.authenticated;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      sessionStatus = SuperadminSessionStatus.signedOut;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    saving = true;
    notifyListeners();
    try {
      await _repository.logout();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      session = null;
      tenantPage = const TenantPage(
        items: [],
        total: 0,
        page: 1,
        pageSize: 100,
      );
      selectedTenant = null;
      ownersByTenant.clear();
      sessionStatus = SuperadminSessionStatus.signedOut;
      saving = false;
      notifyListeners();
    }
  }

  Future<void> load({int page = 1, String? search, String? status}) async {
    loading = true;
    errorMessage = null;
    this.search = search ?? this.search;
    statusFilter = status;
    notifyListeners();
    try {
      tenantPage = await _repository.getTenants(
        page: page,
        pageSize: 100,
        search: this.search,
        status: statusFilter,
      );
    } on ApiException catch (error) {
      _handleError(error);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadTenant(String tenantId) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      selectedTenant = await _repository.getTenant(tenantId);
      _replaceTenant(selectedTenant!);
    } on ApiException catch (error) {
      _handleError(error);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createTenant(Map<String, Object?> payload) =>
      _mutateTenant(() => _repository.createTenant(payload));

  Future<bool> updateTenant(String tenantId, Map<String, Object?> payload) =>
      _mutateTenant(() => _repository.updateTenant(tenantId, payload));

  Future<bool> changeTenantStatus(String tenantId, String status) =>
      _mutateTenant(() => _repository.changeTenantStatus(tenantId, status));

  Future<bool> updateModules(
    String tenantId,
    List<TenantModule> modules,
  ) async {
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.updateTenantModules(tenantId, modules);
      await loadTenant(tenantId);
      return updated.isNotEmpty;
    } on ApiException catch (error) {
      _handleError(error);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> createOwner(Map<String, Object?> payload) => _mutateOwner(
    payload['tenantId']! as String,
    () => _repository.createOwner(payload),
  );

  Future<bool> updateOwner(String tenantId, Map<String, Object?> payload) =>
      _mutateOwner(tenantId, () => _repository.updateOwner(tenantId, payload));

  Future<bool> changeOwnerStatus(String tenantId, String status) =>
      _mutateOwner(
        tenantId,
        () => _repository.changeOwnerStatus(tenantId, status),
      );

  Future<bool> _mutateTenant(
    Future<PlatformTenant> Function() operation,
  ) async {
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final tenant = await operation();
      selectedTenant = tenant;
      _replaceTenant(tenant);
      return true;
    } on ApiException catch (error) {
      _handleError(error);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> _mutateOwner(
    String tenantId,
    Future<OwnerAccount> Function() operation,
  ) async {
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      ownersByTenant[tenantId] = await operation();
      return true;
    } on ApiException catch (error) {
      _handleError(error);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void _replaceTenant(PlatformTenant tenant) {
    final items = [...tenantPage.items];
    final index = items.indexWhere((candidate) => candidate.id == tenant.id);
    if (index < 0) {
      items.insert(0, tenant);
    } else {
      items[index] = tenant;
    }
    tenantPage = TenantPage(
      items: items,
      total: index < 0 ? tenantPage.total + 1 : tenantPage.total,
      page: tenantPage.page,
      pageSize: tenantPage.pageSize,
    );
  }

  void _handleError(ApiException error) {
    errorMessage = error.message;
    if (error.statusCode == 401 || error.statusCode == 403) {
      session = null;
      sessionStatus = SuperadminSessionStatus.signedOut;
    }
  }
}
