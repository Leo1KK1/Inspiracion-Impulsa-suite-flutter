import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../waiter/data/models/waiter_models.dart';
import '../../data/models/restaurant_models.dart';
import '../../data/repositories/restaurant_repository.dart';

class RestaurantController extends ChangeNotifier {
  RestaurantController(
    this._repository, {
    String? initialBranchId,
    this.canUseFloor = false,
    this.canUseKitchen = false,
  }) : branchId = initialBranchId;

  final RestaurantRepository _repository;

  String? branchId;
  bool canUseFloor;
  bool canUseKitchen;
  bool loadingTables = false;
  bool loadingKitchen = false;
  bool loadingDetail = false;
  bool saving = false;
  String? errorMessage;
  List<RestaurantTable> tables = const [];
  List<KitchenOrder> kitchenOrders = const [];
  RestaurantTable? selectedTable;
  List<KitchenOrder> selectedTableOrders = const [];
  String? areaFilterId;
  RestaurantTableStatus? statusFilter;
  KitchenOrderStatus? kitchenStatusFilter;

  CancelToken? _tablesToken;
  CancelToken? _kitchenToken;
  int _branchGeneration = 0;

  bool get loading => loadingTables || loadingKitchen;

  List<RestaurantArea> get areas {
    final byId = <String, RestaurantArea>{};
    for (final table in tables) {
      final area = table.area;
      if (area != null) byId[area.id] = area;
    }
    final values = byId.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  List<RestaurantTable> get filteredTables => tables
      .where((table) {
        return (areaFilterId == null || table.areaId == areaFilterId) &&
            (statusFilter == null || table.status == statusFilter);
      })
      .toList(growable: false);

  Future<void> load({bool force = false}) async {
    if (branchId == null) {
      errorMessage = 'Selecciona una sucursal antes de abrir restaurante.';
      notifyListeners();
      return;
    }
    await Future.wait([
      if (canUseFloor) loadTables(force: force),
      if (canUseKitchen) loadKitchenOrders(force: force),
    ]);
  }

  Future<void> loadTables({bool force = false}) async {
    if (!canUseFloor || branchId == null || (loadingTables && !force)) return;
    _tablesToken?.cancel('Recarga de mesas reemplazada.');
    final token = CancelToken();
    _tablesToken = token;
    final generation = _branchGeneration;
    loadingTables = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getTables(cancelToken: token);
      if (generation != _branchGeneration || token.isCancelled) return;
      tables = result;
      if (areaFilterId != null &&
          !tables.any((table) => table.areaId == areaFilterId)) {
        areaFilterId = null;
      }
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        errorMessage = 'No fue posible cargar las mesas.';
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar las mesas.';
    } finally {
      if (generation == _branchGeneration && identical(_tablesToken, token)) {
        loadingTables = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadKitchenOrders({bool force = false}) async {
    if (!canUseKitchen || branchId == null || (loadingKitchen && !force)) {
      return;
    }
    _kitchenToken?.cancel('Recarga de cocina reemplazada.');
    final token = CancelToken();
    _kitchenToken = token;
    final generation = _branchGeneration;
    loadingKitchen = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getKitchenOrders(
        status: kitchenStatusFilter,
        cancelToken: token,
      );
      if (generation != _branchGeneration || token.isCancelled) return;
      kitchenOrders = result;
    } on DioException catch (error) {
      if (!CancelToken.isCancel(error)) {
        errorMessage = 'No fue posible cargar las comandas de cocina.';
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar las comandas de cocina.';
    } finally {
      if (generation == _branchGeneration && identical(_kitchenToken, token)) {
        loadingKitchen = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadTableDetail(String tableId) async {
    final generation = _branchGeneration;
    loadingDetail = true;
    errorMessage = null;
    selectedTable = null;
    selectedTableOrders = const [];
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _repository.getTable(tableId),
        _repository.getTableOrders(tableId),
      ]);
      if (generation != _branchGeneration) return;
      selectedTable = results[0] as RestaurantTable;
      selectedTableOrders = results[1] as List<KitchenOrder>;
      _replaceTable(selectedTable!);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } on Object {
      errorMessage = 'No fue posible cargar el detalle de la mesa.';
    }
    if (generation != _branchGeneration) return;
    loadingDetail = false;
    notifyListeners();
  }

  Future<bool> openSession(
    String tableId,
    OpenTableSessionRequest request,
  ) async => _mutate(() async {
    await _repository.openSession(tableId, request);
    await loadTableDetail(tableId);
    await loadTables(force: true);
  });

  Future<bool> assignWaiter(String tableId, String waiterUserId) async =>
      _mutate(() async {
        await _repository.assignWaiter(
          tableId,
          waiterUserId: waiterUserId.trim(),
        );
        await loadTableDetail(tableId);
        await loadTables(force: true);
      });

  Future<bool> updateKitchenItemStatus(
    KitchenOrder order,
    KitchenOrderItem item,
    KitchenItemStatus status,
  ) async => _mutate(() async {
    final updated = await _repository.updateKitchenItemStatus(
      order.id,
      item.id,
      status,
    );
    kitchenOrders = [
      for (final current in kitchenOrders)
        if (current.id == updated.id) updated else current,
    ];
  });

  void setArea(String? value) {
    areaFilterId = value;
    notifyListeners();
  }

  void setStatus(RestaurantTableStatus? value) {
    statusFilter = value;
    notifyListeners();
  }

  Future<void> setKitchenStatus(KitchenOrderStatus? value) async {
    kitchenStatusFilter = value;
    await loadKitchenOrders(force: true);
  }

  void updateSession({
    required String? branchId,
    required bool canUseFloor,
    required bool canUseKitchen,
  }) {
    this.canUseFloor = canUseFloor;
    this.canUseKitchen = canUseKitchen;
    if (branchId == this.branchId) return;
    this.branchId = branchId;
    invalidate();
  }

  void invalidate() {
    _branchGeneration++;
    _tablesToken?.cancel('Cambió la sucursal activa.');
    _kitchenToken?.cancel('Cambió la sucursal activa.');
    loadingTables = false;
    loadingKitchen = false;
    loadingDetail = false;
    saving = false;
    errorMessage = null;
    tables = const [];
    kitchenOrders = const [];
    selectedTable = null;
    selectedTableOrders = const [];
    areaFilterId = null;
    statusFilter = null;
    kitchenStatusFilter = null;
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

  void _replaceTable(RestaurantTable table) {
    final index = tables.indexWhere((item) => item.id == table.id);
    if (index == -1) {
      tables = [...tables, table];
      return;
    }
    final copy = [...tables];
    copy[index] = table;
    tables = copy;
  }

  @override
  void dispose() {
    _tablesToken?.cancel('Controlador cerrado.');
    _kitchenToken?.cancel('Controlador cerrado.');
    super.dispose();
  }
}
