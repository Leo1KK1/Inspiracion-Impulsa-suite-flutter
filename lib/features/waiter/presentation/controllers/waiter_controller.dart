import 'package:flutter/foundation.dart';

import '../../data/models/waiter_models.dart';
import '../../data/repositories/waiter_repository.dart';

class WaiterController extends ChangeNotifier {
  WaiterController(this._repository);
  final WaiterRepository _repository;

  bool loading = false;
  List<MenuProduct> menu = const [];
  List<WaiterOrderLine> order = const [];
  String query = '';
  String category = 'Todos';
  String specialNotes = '';

  Future<void> load({String? branchId}) async {
    loading = true;
    notifyListeners();
    menu = await _repository.getMenu(branchId: branchId);
    loading = false;
    notifyListeners();
  }

  Future<List<ComandaItem>> getOrderItems(String id) =>
      _repository.getOrderItems(id);

  List<MenuProduct> get filteredMenu => menu.where((product) {
    return product.name.toLowerCase().contains(query.toLowerCase()) &&
        (category == 'Todos' || product.category == category);
  }).toList();

  double get subtotal =>
      order.fold(0, (sum, line) => sum + line.product.price * line.quantity);
  double get tax => subtotal * 0.16;
  double get total => subtotal + tax;

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void setSpecialNotes(String value) {
    specialNotes = value;
    notifyListeners();
  }

  void add(MenuProduct product) {
    final index = order.indexWhere((line) => line.product.id == product.id);
    if (index == -1) {
      order = [...order, WaiterOrderLine(product: product, quantity: 1)];
    } else {
      final copy = [...order];
      copy[index] = copy[index].copyWith(quantity: copy[index].quantity + 1);
      order = copy;
    }
    notifyListeners();
  }

  void changeQuantity(MenuProduct product, int delta) {
    final index = order.indexWhere((line) => line.product.id == product.id);
    if (index == -1) return;
    final next = order[index].quantity + delta;
    if (next <= 0) {
      order = order.where((line) => line.product.id != product.id).toList();
    } else {
      final copy = [...order];
      copy[index] = copy[index].copyWith(quantity: next);
      order = copy;
    }
    notifyListeners();
  }

  void setLineNotes(MenuProduct product, String notes) {
    final index = order.indexWhere((line) => line.product.id == product.id);
    if (index == -1) return;
    final copy = [...order];
    copy[index] = copy[index].copyWith(notes: notes);
    order = copy;
    notifyListeners();
  }

  void clearOrder() {
    order = const [];
    specialNotes = '';
    notifyListeners();
  }
}
