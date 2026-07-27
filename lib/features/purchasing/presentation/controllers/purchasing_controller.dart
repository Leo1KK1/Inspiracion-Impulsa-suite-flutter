import 'package:flutter/foundation.dart';

import '../../data/models/purchasing_models.dart';
import '../../data/repositories/purchasing_repository.dart';

enum PurchasingStatus { idle, loading, success, error }

class PurchasingController extends ChangeNotifier {
  PurchasingController(this._repository);
  final PurchasingRepository _repository;

  PurchasingStatus status = PurchasingStatus.idle;
  List<PurchaseOrder> orders = const [];
  List<Supplier> suppliers = const [];
  String? errorMessage;

  Future<void> load() async {
    status = PurchasingStatus.loading;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getOrders(),
        _repository.getSuppliers(),
      ]);
      orders = results[0] as List<PurchaseOrder>;
      suppliers = results[1] as List<Supplier>;
      status = PurchasingStatus.success;
    } on Object {
      errorMessage = 'No fue posible cargar compras y proveedores.';
      status = PurchasingStatus.error;
    }
    notifyListeners();
  }

  Future<List<PurchaseOrderLine>> getLines(String orderId) {
    return _repository.getOrderLines(orderId);
  }

  void addOrder(PurchaseOrder order) {
    orders = [...orders, order];
    notifyListeners();
  }
}
