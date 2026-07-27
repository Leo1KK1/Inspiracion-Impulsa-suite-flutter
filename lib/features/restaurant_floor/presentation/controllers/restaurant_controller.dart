import 'package:flutter/material.dart';

import '../../data/models/restaurant_models.dart';
import '../../data/repositories/restaurant_repository.dart';

class RestaurantController extends ChangeNotifier {
  RestaurantController(this._repository);
  final RestaurantRepository _repository;

  bool loading = false;
  List<RestaurantTable> tables = const [];
  List<KitchenOrder> kitchenOrders = const [];
  RestaurantZone? zoneFilter;
  RestaurantTableStatus? statusFilter;
  bool rearrangeMode = false;
  final Map<String, Offset> positions = {};

  Future<void> load({String? branchId}) async {
    loading = true;
    notifyListeners();
    final result = await Future.wait<Object>([
      _repository.getTables(branchId: branchId),
      _repository.getKitchenOrders(branchId: branchId),
    ]);
    tables = result[0] as List<RestaurantTable>;
    kitchenOrders = result[1] as List<KitchenOrder>;
    _initPositions();
    loading = false;
    notifyListeners();
  }

  List<RestaurantTable> get filteredTables => tables.where((table) {
    return (zoneFilter == null || table.zone == zoneFilter) &&
        (statusFilter == null || table.status == statusFilter);
  }).toList();

  void setZone(RestaurantZone? value) {
    zoneFilter = value;
    notifyListeners();
  }

  void setStatus(RestaurantTableStatus? value) {
    statusFilter = value;
    notifyListeners();
  }

  void toggleRearrange() {
    rearrangeMode = !rearrangeMode;
    notifyListeners();
  }

  void moveTable(String id, Offset delta) {
    final current = positions[id] ?? Offset.zero;
    positions[id] = Offset(
      (current.dx + delta.dx).clamp(0, 824).toDouble(),
      (current.dy + delta.dy).clamp(0, 444).toDouble(),
    );
    notifyListeners();
  }

  void advanceKitchenOrder(String id) {
    kitchenOrders = [
      for (final order in kitchenOrders)
        if (order.id == id)
          order.copyWith(status: _nextStatus(order.status))
        else
          order,
    ];
    notifyListeners();
  }

  KitchenOrderStatus _nextStatus(KitchenOrderStatus status) => switch (status) {
    KitchenOrderStatus.newOrder => KitchenOrderStatus.inPreparation,
    KitchenOrderStatus.inPreparation => KitchenOrderStatus.ready,
    KitchenOrderStatus.ready => KitchenOrderStatus.delivered,
    KitchenOrderStatus.delivered => KitchenOrderStatus.delivered,
  };

  void _initPositions() {
    if (positions.isNotEmpty) return;
    for (var i = 0; i < tables.length; i++) {
      positions[tables[i].id] = Offset(22 + (i % 9) * 98, 22 + (i ~/ 9) * 124);
    }
  }
}
