import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/tenant_session.dart';
import '../../data/repositories/session_repository.dart';

enum SessionStatus { restoring, signedOut, authenticated, failure }

class TenantSessionController extends ChangeNotifier {
  TenantSessionController(this._repository);

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

  Future<void> restore() async {
    _status = SessionStatus.restoring;
    notifyListeners();
    try {
      _session = await _repository.restore();
      _status = _session == null
          ? SessionStatus.signedOut
          : SessionStatus.authenticated;
    } on Object {
      _status = SessionStatus.failure;
      _errorMessage = 'No fue posible restaurar la sesión.';
    }
    notifyListeners();
  }

  Future<bool> loginTenant({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@') || password.trim().isEmpty) {
      _errorMessage = 'Ingresa un correo válido y tu contraseña.';
      notifyListeners();
      return false;
    }
    _status = SessionStatus.restoring;
    _errorMessage = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 550));
    _session = TenantSession(
      authContext: 'tenant',
      actorId: 'USR-MX-104',
      actorType: 'employee',
      tenantId: 'GVS-MX-001',
      tenantName: 'Grupo Vega S.A.',
      activeBranchId: 'CDMX-01',
      activeBranchName: 'Sucursal CDMX Centro',
      roleCodes: const ['BRANCH_MANAGER', 'OWNER', 'CASHIER', 'WAITER'],
      sessionId: const Uuid().v4(),
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      userName: 'María López',
      userEmail: email,
    );
    await _repository.save(_session!);
    _status = SessionStatus.authenticated;
    notifyListeners();
    return true;
  }

  Future<void> switchBranch(String id, String name) async {
    final current = _session;
    if (current == null) return;
    _session = current.copyWith(activeBranchId: id, activeBranchName: name);
    await _repository.save(_session!);
    notifyListeners();
  }

  bool hasAnyRole(Iterable<String> allowed) {
    return roleCodes.any(allowed.contains);
  }

  Future<void> logout() async {
    await _repository.clear();
    _session = null;
    _status = SessionStatus.signedOut;
    notifyListeners();
  }
}
