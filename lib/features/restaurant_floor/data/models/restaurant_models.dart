enum RestaurantZone { salon, terraza, barra, privado }

enum RestaurantTableStatus {
  available,
  occupied,
  waitingOrder,
  inPreparation,
  readyToBill,
  dirty,
  reserved,
}

class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.number,
    required this.zone,
    required this.status,
    required this.capacity,
    required this.guestCount,
    this.waiterName,
    this.openedMinutes,
    this.reservedFor,
    required this.total,
  });

  final String id;
  final int number;
  final RestaurantZone zone;
  final RestaurantTableStatus status;
  final int capacity;
  final int guestCount;
  final String? waiterName;
  final int? openedMinutes;
  final String? reservedFor;
  final double total;
}

enum KitchenOrderStatus { newOrder, inPreparation, ready, delivered }

enum KitchenStation { caliente, fria, bebidas }

class KitchenOrderItem {
  const KitchenOrderItem({
    required this.name,
    required this.quantity,
    required this.station,
    this.notes,
  });
  final String name;
  final int quantity;
  final KitchenStation station;
  final String? notes;
}

class KitchenOrder {
  const KitchenOrder({
    required this.id,
    required this.tableNumber,
    required this.zone,
    required this.waiterName,
    required this.items,
    required this.status,
    required this.sentMinutesAgo,
  });

  final String id;
  final int tableNumber;
  final RestaurantZone zone;
  final String waiterName;
  final List<KitchenOrderItem> items;
  final KitchenOrderStatus status;
  final int sentMinutesAgo;
  bool get urgent => sentMinutesAgo > 20;

  KitchenOrder copyWith({KitchenOrderStatus? status}) => KitchenOrder(
    id: id,
    tableNumber: tableNumber,
    zone: zone,
    waiterName: waiterName,
    items: items,
    status: status ?? this.status,
    sentMinutesAgo: sentMinutesAgo,
  );
}
