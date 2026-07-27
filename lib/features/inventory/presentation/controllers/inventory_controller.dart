import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/inventory_models.dart';
import '../../data/repositories/inventory_repository.dart';

enum InventoryStatus { idle, loading, success, empty, error }

class InventoryController extends ChangeNotifier {
  InventoryController(this._repository, {String? initialBranchId})
    : branchId = initialBranchId;

  final InventoryRepository _repository;
  InventoryStatus status = InventoryStatus.idle;
  List<Product> products = const [];
  List<InventoryCategory> categories = const [];
  List<InventoryItem> stock = const [];
  List<InventoryItem> alerts = const [];
  List<InventoryMovement> movements = const [];
  String query = '';
  String? categoryId;
  String? statusFilter;
  String? branchId;
  String? errorMessage;
  bool saving = false;

  Future<void> load({String? branchId, bool force = false}) async {
    if (branchId != null) this.branchId = branchId;
    final activeBranch = this.branchId;
    if (activeBranch == null) {
      status = InventoryStatus.error;
      errorMessage = 'Selecciona una sucursal antes de consultar inventario.';
      notifyListeners();
      return;
    }
    if (status == InventoryStatus.loading || (!force && products.isNotEmpty)) {
      return;
    }
    status = InventoryStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getProducts(),
        _repository.getCategories(),
        _repository.getBranchInventory(activeBranch),
        _repository.getAlerts(branchId: activeBranch),
        _repository.getMovements(activeBranch),
      ]);
      products = results[0] as List<Product>;
      categories = results[1] as List<InventoryCategory>;
      stock = results[2] as List<InventoryItem>;
      alerts = results[3] as List<InventoryItem>;
      movements = results[4] as List<InventoryMovement>;
      status = products.isEmpty
          ? InventoryStatus.empty
          : InventoryStatus.success;
    } on ApiException catch (error) {
      errorMessage = error.message;
      status = InventoryStatus.error;
    } on Object {
      errorMessage = 'No fue posible cargar el inventario.';
      status = InventoryStatus.error;
    }
    notifyListeners();
  }

  List<Product> get filteredProducts => products
      .where((product) {
        final text = query.trim().toLowerCase();
        return (text.isEmpty ||
                product.name.toLowerCase().contains(text) ||
                product.sku.toLowerCase().contains(text) ||
                product.barcode?.toLowerCase().contains(text) == true) &&
            (categoryId == null || product.categoryId == categoryId) &&
            (statusFilter == null ||
                product.status.name.toUpperCase() == statusFilter);
      })
      .toList(growable: false);

  InventoryItem? stockFor(String productId) =>
      stock.where((item) => item.productId == productId).firstOrNull;

  List<InventoryMovement> movementsFor(String productId) => movements
      .where((movement) => movement.productId == productId)
      .toList(growable: false);

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    categoryId = value;
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    statusFilter = value;
    notifyListeners();
  }

  void setBranch(String? value) {
    if (value == branchId) return;
    branchId = value;
    invalidate();
  }

  void invalidate() {
    products = const [];
    categories = const [];
    stock = const [];
    alerts = const [];
    movements = const [];
    status = InventoryStatus.idle;
    notifyListeners();
  }

  Future<bool> createCategory(Map<String, Object?> payload) =>
      _mutate(() => _repository.createCategory(payload));
  Future<bool> updateCategory(String id, Map<String, Object?> payload) =>
      _mutate(() => _repository.updateCategory(id, payload));
  Future<bool> changeCategoryStatus(String id, bool active) =>
      _mutate(() => _repository.changeCategoryStatus(id, active));
  Future<bool> createProduct(Map<String, Object?> payload) =>
      _mutate(() => _repository.createProduct(payload));
  Future<bool> updateProduct(String id, Map<String, Object?> payload) =>
      _mutate(() => _repository.updateProduct(id, payload));
  Future<bool> changeProductStatus(String id, String value) =>
      _mutate(() => _repository.changeProductStatus(id, value));
  Future<bool> deleteProductImage(String productId, String imageId) =>
      _mutate(() => _repository.deleteProductImage(productId, imageId));
  Future<bool> adjustStock(Map<String, Object?> payload) =>
      _branchMutate((id) => _repository.adjustStock(id, payload));
  Future<bool> updateMinStock(Map<String, Object?> payload) =>
      _branchMutate((id) => _repository.updateMinStock(id, payload));
  Future<bool> reserveStock(Map<String, Object?> payload) =>
      _branchMutate((id) => _repository.reserveStock(id, payload));

  Future<bool> _branchMutate(Future<void> Function(String branchId) action) {
    final current = branchId;
    if (current == null) {
      errorMessage = 'No hay una sucursal activa.';
      notifyListeners();
      return Future.value(false);
    }
    return _mutate(() => action(current));
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
