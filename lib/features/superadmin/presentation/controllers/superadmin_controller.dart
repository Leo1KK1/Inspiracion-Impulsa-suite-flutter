import 'package:flutter/foundation.dart';

import '../../data/models/superadmin_models.dart';
import '../../data/repositories/superadmin_repository.dart';

class SuperadminController extends ChangeNotifier {
  SuperadminController(this._repository);

  final SuperadminRepository _repository;
  bool loading = false;
  String? errorMessage;
  List<PlatformTenant> tenants = const [];
  String query = '';

  List<PlatformTenant> get filteredTenants => tenants
      .where(
        (tenant) =>
            tenant.name.toLowerCase().contains(query.toLowerCase()) ||
            tenant.id.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      tenants = await _repository.getTenants();
    } on Object {
      errorMessage = 'No fue posible cargar los tenants.';
    }
    loading = false;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void toggleTenant(String id) {
    tenants = [
      for (final tenant in tenants)
        if (tenant.id == id)
          tenant.copyWith(
            status: tenant.status == 'SUSPENDIDO' ? 'ACTIVO' : 'SUSPENDIDO',
          )
        else
          tenant,
    ];
    notifyListeners();
  }
}
