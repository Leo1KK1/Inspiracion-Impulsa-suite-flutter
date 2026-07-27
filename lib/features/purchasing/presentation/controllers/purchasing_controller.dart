import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/purchasing_models.dart';
import '../../data/repositories/purchasing_repository.dart';

enum PurchasingStatus { idle, loading, success, error }

class PurchasingController extends ChangeNotifier {
  PurchasingController(this._repository, {String? initialBranchId})
    : branchId = initialBranchId;

  final PurchasingRepository _repository;
  PurchasingStatus status = PurchasingStatus.idle;
  List<PurchaseOrder> orders = const [];
  List<Supplier> suppliers = const [];
  final Map<String, PurchaseOrder> _details = {};
  String? branchId;
  String? errorMessage;
  bool saving = false;

  Future<void> load({String? branchId, bool force = false}) async {
    if (branchId != null) this.branchId = branchId;
    if (this.branchId == null) {
      status = PurchasingStatus.error;
      errorMessage = 'Selecciona una sucursal antes de consultar compras.';
      notifyListeners();
      return;
    }
    if (status == PurchasingStatus.loading || (!force && orders.isNotEmpty)) {
      return;
    }
    status = PurchasingStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getOrders(branchId: this.branchId),
        _repository.getSuppliers(),
      ]);
      orders = results[0] as List<PurchaseOrder>;
      suppliers = results[1] as List<Supplier>;
      status = PurchasingStatus.success;
    } on ApiException catch (error) {
      errorMessage = error.message;
      status = PurchasingStatus.error;
    } on Object {
      errorMessage = 'No fue posible cargar compras y proveedores.';
      status = PurchasingStatus.error;
    }
    notifyListeners();
  }

  Future<PurchaseOrder?> getOrder(String id, {bool force = false}) async {
    final cached = _details[id];
    if (!force && cached != null) return cached;
    try {
      final order = await _repository.getOrder(id);
      _details[id] = order;
      notifyListeners();
      return order;
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return null;
    }
  }

  void setBranch(String? value) {
    if (value == branchId) return;
    branchId = value;
    invalidate();
  }

  void invalidate() {
    orders = const [];
    suppliers = const [];
    _details.clear();
    status = PurchasingStatus.idle;
    notifyListeners();
  }

  Future<bool> createSupplier(Map<String, Object?> payload) =>
      _mutate(() => _repository.createSupplier(payload));
  Future<bool> updateSupplier(String id, Map<String, Object?> payload) =>
      _mutate(() => _repository.updateSupplier(id, payload));
  Future<bool> createOrder(Map<String, Object?> payload) {
    final branch = branchId;
    if (branch == null) return Future.value(false);
    return _mutate(() => _repository.createOrder(branch, payload));
  }

  Future<bool> updateOrder(String id, Map<String, Object?> payload) =>
      _mutate(() => _repository.updateOrder(id, payload), detailId: id);
  Future<bool> submitOrder(String id) =>
      _mutate(() => _repository.submitOrder(id), detailId: id);
  Future<bool> cancelOrder(String id) =>
      _mutate(() => _repository.cancelOrder(id), detailId: id);
  Future<bool> receiveOrder(String id, Map<String, Object?> payload) {
    final branch = branchId;
    if (branch == null) return Future.value(false);
    return _mutate(
      () => _repository.receiveOrder(id, branch, payload),
      detailId: id,
    );
  }

  Future<bool> _mutate(
    Future<void> Function() action, {
    String? detailId,
  }) async {
    if (saving) return false;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      if (detailId != null) _details.remove(detailId);
      saving = false;
      await load(force: true);
      if (detailId != null) await getOrder(detailId, force: true);
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
