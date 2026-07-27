import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/tenant_session.dart';
import '../../data/repositories/session_repository.dart';

enum SessionStatus { restoring, signedOut, authenticated, failure }

class TenantSessionController extends ChangeNotifier {
  TenantSessionController(this._repository) {
    _repository.setSessionListener(_onRepositorySessionChanged);
  }

  final SessionRepository _repository;
  SessionStatus _status = SessionStatus.restoring;
  TenantSession? _session;
  String? _errorMessage;

  SessionStatus get status => _status;
  TenantSession? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == SessionStatus.authenticated;
  bool get isTenant =>
      isAuthenticated && _session?.authContext.toLowerCase() == 'tenant';
  String? get activeBranchId => _session?.activeBranchId;
  List<String> get roleCodes => _session?.roleCodes ?? const [];
  List<String> get permissions => _session?.permissions ?? const [];
  List<TenantBranchAccess> get branches => _session?.branches ?? const [];
  bool get isOwner => roleCodes.contains('OWNER');
  bool get isManager => roleCodes.contains('MANAGER');
  bool get canSwitchBranch => isOwner || isManager;

  Future<void> restore() async {
    _status = SessionStatus.restoring;
    _errorMessage = null;
    notifyListeners();
    try {
      _session = await _repository.restore();
      _status = _session == null
          ? SessionStatus.signedOut
          : SessionStatus.authenticated;
    } on ApiException catch (error) {
      _status = SessionStatus.failure;
      _errorMessage = error.message;
    } on Object {
      _status = SessionStatus.failure;
      _errorMessage = 'No fue posible restaurar la sesión.';
    }
    notifyListeners();
  }

  Future<bool> loginTenant({
    required String tenantSlug,
    required String email,
    required String password,
  }) async {
    if (tenantSlug.trim().isEmpty ||
        !email.contains('@') ||
        password.length < 8) {
      _errorMessage =
          'Ingresa el identificador del negocio, un correo válido y una contraseña de al menos 8 caracteres.';
      notifyListeners();
      return false;
    }
    _status = SessionStatus.restoring;
    _errorMessage = null;
    notifyListeners();
    try {
      _session = await _repository.login(
        tenantSlug: tenantSlug,
        email: email,
        password: password,
      );
      _status = SessionStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _status = SessionStatus.signedOut;
      _errorMessage = error.message;
    } on Object {
      _status = SessionStatus.signedOut;
      _errorMessage = 'No fue posible iniciar sesión.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> switchBranch(String branchId) async {
    if (!canSwitchBranch || branchId == activeBranchId) return false;
    _errorMessage = null;
    try {
      _session = await _repository.switchBranch(branchId);
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } on Object {
      _errorMessage = 'No fue posible cambiar de sucursal.';
    }
    notifyListeners();
    return false;
  }

  bool hasAnyRole(Iterable<String> allowed) => roleCodes.any(allowed.contains);

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      _session = null;
      _status = SessionStatus.signedOut;
      notifyListeners();
    }
  }

  void _onRepositorySessionChanged(TenantSession? session) {
    _session = session;
    _status = session == null
        ? SessionStatus.signedOut
        : SessionStatus.authenticated;
    notifyListeners();
  }
}
