import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../restaurant_floor/data/models/restaurant_models.dart';
import '../../../restaurant_floor/data/repositories/restaurant_repository.dart';
import '../../data/models/waiter_models.dart';

class WaiterController extends ChangeNotifier {
  WaiterController(this._repository, {String? initialBranchId})
    : branchId = initialBranchId;

  final RestaurantRepository _repository;

  String? branchId;
  bool loadingMenu = false;
  bool loadingTable = false;
  bool loadingOrder = false;
  bool saving = false;
  String? errorMessage;
  List<MenuProduct> menu = const [];
  List<WaiterOrderLine> order = const [];
  RestaurantTable? activeTable;
  List<KitchenOrder> tableOrders = const [];
  KitchenOrder? selectedOrder;
  SplitBillResult? splitResult;
  RestaurantCheckoutResult? checkoutResult;
  String query = '';
  String category = 'Todos';
  String specialNotes = '';

  Timer? _searchDebounce;
  CancelToken? _menuToken;
  int _generation = 0;

  bool get loading => loadingMenu || loadingTable || loadingOrder;
  double get subtotal => order.fold(0, (sum, line) => sum + line.total);
  double get total => subtotal;

  List<String> get categories => [
    'Todos',
    ...{for (final product in menu) product.category},
  ];

  List<MenuProduct> get filteredMenu => menu
      .where((product) => category == 'Todos' || product.category == category)
      .toList(growable: false);

  Future<void> loadMenu({bool force = false}) async {
    if (branchId == null || (loadingMenu && !force)) return;
    _menuToken?.cancel('Búsqueda de menú reemplazada.');
    final token = CancelToken();
    _menuToken = token;
    final generation = _generation;
    loadingMenu = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.searchMenu(
        query,
        limit: 100,
        cancelToken: token,
      );
      if (generation != _generation || token.isCancelled) return;
      menu = result;
      if (!categories.contains(category)) category = 'Todos';
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        errorMessage = 'No fue posible cargar el menú.';
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar el menú.';
    } finally {
      if (generation == _generation && identical(_menuToken, token)) {
        loadingMenu = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadTable(String tableId) async {
    final generation = _generation;
    loadingTable = true;
    errorMessage = null;
    splitResult = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getTable(tableId),
        _repository.getTableOrders(tableId),
        if (menu.isEmpty) _repository.searchMenu('', limit: 100),
      ]);
      if (generation != _generation) return;
      activeTable = results[0] as RestaurantTable;
      tableOrders = results[1] as List<KitchenOrder>;
      if (results.length > 2) menu = results[2] as List<MenuProduct>;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar la sesión de mesa.';
    }
    if (generation != _generation) return;
    loadingTable = false;
    notifyListeners();
  }

  Future<void> loadOrder(String orderId) async {
    final generation = _generation;
    loadingOrder = true;
    errorMessage = null;
    selectedOrder = null;
    notifyListeners();
    try {
      final result = await _repository.getKitchenOrder(orderId);
      if (generation != _generation) return;
      selectedOrder = result;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible consultar la comanda.';
    }
    if (generation != _generation) return;
    loadingOrder = false;
    notifyListeners();
  }

  Future<bool> openSession(
    String tableId,
    OpenTableSessionRequest request,
  ) async => _mutate(() async {
    await _repository.openSession(tableId, request);
    await loadTable(tableId);
  });

  Future<void> add(MenuProduct product) async {
    if (saving) return;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final current = await _repository.getProduct(product.id);
      final index = order.indexWhere((line) => line.product.id == current.id);
      final currentQuantity = index == -1 ? 0 : order[index].quantity;
      if (currentQuantity >= current.availableStock) {
        errorMessage =
            'Solo hay ${current.availableStock} unidades disponibles.';
      } else if (index == -1) {
        order = [...order, WaiterOrderLine(product: current, quantity: 1)];
      } else {
        final copy = [...order];
        copy[index] = copy[index].copyWith(
          product: current,
          quantity: currentQuantity + 1,
        );
        order = copy;
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible validar el producto.';
    }
    saving = false;
    notifyListeners();
  }

  void changeQuantity(MenuProduct product, int delta) {
    final index = order.indexWhere((line) => line.product.id == product.id);
    if (index == -1 || saving) return;
    final next = order[index].quantity + delta;
    if (next <= 0) {
      order = order.where((line) => line.product.id != product.id).toList();
    } else if (next > order[index].product.availableStock) {
      errorMessage =
          'Solo hay ${order[index].product.availableStock} unidades disponibles.';
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

  Future<KitchenOrder?> createAndSendOrder(String tableId) async {
    KitchenOrder? result;
    final success = await _mutate(() async {
      final created = await _repository.createOrder(
        tableId,
        items: List<WaiterOrderLine>.unmodifiable(order),
        notes: specialNotes,
      );
      result = await _repository.sendToKitchen(created.id);
      order = const [];
      specialNotes = '';
      await loadTable(tableId);
    });
    return success ? result : null;
  }

  Future<bool> sendExistingOrder(String tableId, String orderId) async =>
      _mutate(() async {
        await _repository.sendToKitchen(orderId);
        await loadTable(tableId);
      });

  Future<bool> updateOrderStatus(
    String orderId,
    KitchenOrderStatus status, {
    String? tableId,
  }) async => _mutate(() async {
    final updated = await _repository.updateOrderStatus(orderId, status);
    selectedOrder = selectedOrder?.id == updated.id ? updated : selectedOrder;
    if (tableId != null) await loadTable(tableId);
  });

  Future<bool> splitEqual(String tableId, int parts) async => _mutate(() async {
    splitResult = await _repository.splitBillEqual(tableId, parts: parts);
  });

  Future<bool> splitByItem(
    String tableId,
    List<SplitBillAssignment> assignments,
  ) async => _mutate(() async {
    splitResult = await _repository.splitBillByItem(
      tableId,
      assignments: assignments,
    );
  });

  Future<bool> checkout(
    String tableId,
    RestaurantCheckoutRequest request,
  ) async => _mutate(() async {
    checkoutResult = await _repository.checkout(tableId, request);
    order = const [];
    specialNotes = '';
    await loadTable(tableId);
  });

  void setQuery(String value) {
    query = value;
    category = 'Todos';
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => loadMenu(force: true),
    );
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

  void clearOrder() {
    order = const [];
    specialNotes = '';
    notifyListeners();
  }

  void clearSplitResult() {
    splitResult = null;
    notifyListeners();
  }

  void updateBranch(String? value) {
    if (value == branchId) return;
    branchId = value;
    invalidate();
  }

  void invalidate() {
    _generation++;
    _searchDebounce?.cancel();
    _menuToken?.cancel('Cambió la sucursal activa.');
    loadingMenu = false;
    loadingTable = false;
    loadingOrder = false;
    saving = false;
    errorMessage = null;
    menu = const [];
    order = const [];
    activeTable = null;
    tableOrders = const [];
    selectedOrder = null;
    splitResult = null;
    checkoutResult = null;
    query = '';
    category = 'Todos';
    specialNotes = '';
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (saving) return false;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      saving = false;
      notifyListeners();
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _menuToken?.cancel('Controlador cerrado.');
    super.dispose();
  }
}
