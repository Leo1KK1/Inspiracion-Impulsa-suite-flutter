import 'package:flutter/foundation.dart';

import '../../data/models/inventory_models.dart';
import '../../data/repositories/inventory_repository.dart';

enum InventoryStatus { idle, loading, success, empty, error }

class InventoryController extends ChangeNotifier {
  InventoryController(this._repository);
  final InventoryRepository _repository;

  InventoryStatus status = InventoryStatus.idle;
  List<Product> products = const [];
  List<InventoryCategory> categories = const [];
  List<StockAlert> alerts = const [];
  String query = '';
  String category = 'Todas';
  String? errorMessage;

  Future<void> load({String? branchId}) async {
    status = InventoryStatus.loading;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getProducts(branchId: branchId),
        _repository.getCategories(),
        _repository.getAlerts(branchId: branchId),
      ]);
      products = results[0] as List<Product>;
      categories = results[1] as List<InventoryCategory>;
      alerts = results[2] as List<StockAlert>;
      status = products.isEmpty
          ? InventoryStatus.empty
          : InventoryStatus.success;
    } on Object {
      errorMessage = 'No fue posible cargar el inventario.';
      status = InventoryStatus.error;
    }
    notifyListeners();
  }

  List<Product> get filteredProducts => products.where((product) {
    final matchesText =
        product.name.toLowerCase().contains(query.toLowerCase()) ||
        product.sku.toLowerCase().contains(query.toLowerCase());
    final matchesCategory = category == 'Todas' || product.category == category;
    return matchesText && matchesCategory;
  }).toList();

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void addProduct(Product product) {
    products = [...products, product];
    notifyListeners();
  }
}
