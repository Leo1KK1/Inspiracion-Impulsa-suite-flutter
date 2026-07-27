import 'package:flutter/foundation.dart';

import '../../data/models/pos_models.dart';
import '../../data/repositories/pos_repository.dart';

class PosController extends ChangeNotifier {
  PosController(this._repository);
  final PosRepository _repository;

  bool loading = false;
  bool shiftOpen = true;
  List<PosProduct> products = const [];
  List<PosTicket> tickets = const [];
  List<CartLine> cart = const [];
  String query = '';
  String category = 'Todos';

  Future<void> load({String? branchId}) async {
    loading = true;
    notifyListeners();
    final results = await Future.wait<Object>([
      _repository.getProducts(branchId: branchId),
      _repository.getTickets(branchId: branchId),
    ]);
    products = results[0] as List<PosProduct>;
    tickets = results[1] as List<PosTicket>;
    loading = false;
    notifyListeners();
  }

  List<PosProduct> get filteredProducts => products.where((product) {
    final text = product.name.toLowerCase().contains(query.toLowerCase());
    return text && (category == 'Todos' || product.category == category);
  }).toList();

  double get subtotal =>
      cart.fold(0, (sum, line) => sum + line.product.price * line.quantity);
  double get tax => subtotal * 0.16;
  double get total => subtotal + tax;

  void add(PosProduct product) {
    final existing = cart.indexWhere((line) => line.product.id == product.id);
    if (existing == -1) {
      cart = [...cart, CartLine(product: product, quantity: 1)];
    } else {
      final line = cart[existing];
      cart = [...cart]..[existing] = line.copyWith(quantity: line.quantity + 1);
    }
    notifyListeners();
  }

  void changeQuantity(PosProduct product, int delta) {
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) return;
    final next = cart[index].quantity + delta;
    if (next <= 0) {
      cart = cart.where((line) => line.product.id != product.id).toList();
    } else {
      final copy = [...cart];
      copy[index] = copy[index].copyWith(quantity: next);
      cart = copy;
    }
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void completeSale(PaymentMethod method) {
    tickets = [
      PosTicket(
        id: 't${tickets.length + 1}',
        folio: 'T-${(42 + tickets.length).toString().padLeft(4, '0')}',
        time: '${DateTime.now().hour}:${DateTime.now().minute}',
        status: TicketStatus.completed,
        method: method,
        total: total,
        cashier: 'M. López',
        lines: [...cart],
      ),
      ...tickets,
    ];
    cart = const [];
    notifyListeners();
  }

  void openShift() {
    shiftOpen = true;
    notifyListeners();
  }

  void closeShift() {
    shiftOpen = false;
    notifyListeners();
  }
}
