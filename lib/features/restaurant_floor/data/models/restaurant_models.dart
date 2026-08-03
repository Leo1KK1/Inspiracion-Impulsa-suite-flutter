enum RestaurantTableStatus {
  available,
  occupied,
  reserved,
  dirty;

  String get apiValue => switch (this) {
    available => 'AVAILABLE',
    occupied => 'OCCUPIED',
    reserved => 'RESERVED',
    dirty => 'DIRTY',
  };

  static RestaurantTableStatus fromApi(Object? value) => switch (value) {
    'OCCUPIED' => occupied,
    'RESERVED' => reserved,
    'DIRTY' => dirty,
    _ => available,
  };
}

enum TableSessionStatus {
  open,
  closed,
  cancelled;

  static TableSessionStatus fromApi(Object? value) => switch (value) {
    'CLOSED' => closed,
    'CANCELLED' => cancelled,
    _ => open,
  };
}

enum KitchenOrderStatus {
  pending,
  inPreparation,
  ready,
  delivered,
  cancelled;

  String get apiValue => switch (this) {
    pending => 'PENDING',
    inPreparation => 'IN_PREPARATION',
    ready => 'READY',
    delivered => 'DELIVERED',
    cancelled => 'CANCELLED',
  };

  static KitchenOrderStatus fromApi(Object? value) => switch (value) {
    'IN_PREPARATION' => inPreparation,
    'READY' => ready,
    'DELIVERED' => delivered,
    'CANCELLED' => cancelled,
    _ => pending,
  };
}

enum KitchenItemStatus {
  pending,
  inPreparation,
  ready,
  delivered,
  cancelled;

  String get apiValue => switch (this) {
    pending => 'PENDING',
    inPreparation => 'IN_PREPARATION',
    ready => 'READY',
    delivered => 'DELIVERED',
    cancelled => 'CANCELLED',
  };

  static KitchenItemStatus fromApi(Object? value) => switch (value) {
    'IN_PREPARATION' || 'PREPARING' => inPreparation,
    'READY' => ready,
    'DELIVERED' => delivered,
    'CANCELLED' => cancelled,
    _ => pending,
  };
}

class RestaurantArea {
  const RestaurantArea({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;

  factory RestaurantArea.fromJson(Map<String, Object?> json) => RestaurantArea(
    id: _string(json['id']),
    name: _string(json['name'], fallback: 'Sin área'),
    code: _string(json['code']),
    description: json['description'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );
}

class RestaurantUserRef {
  const RestaurantUserRef({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory RestaurantUserRef.fromJson(Map<String, Object?> json) =>
      RestaurantUserRef(
        id: _string(json['id']),
        fullName: _string(json['fullName'], fallback: 'Usuario'),
        email: _string(json['email']),
      );
}

class RestaurantTableRef {
  const RestaurantTableRef({
    required this.id,
    required this.number,
    required this.name,
    required this.capacity,
    required this.status,
    this.area,
  });

  final String id;
  final int number;
  final String name;
  final int capacity;
  final RestaurantTableStatus status;
  final RestaurantArea? area;

  factory RestaurantTableRef.fromJson(Map<String, Object?> json) =>
      RestaurantTableRef(
        id: _string(json['id']),
        number: _int(json['number']),
        name: _string(json['name'], fallback: 'Mesa ${_int(json['number'])}'),
        capacity: _int(json['capacity'], fallback: 1),
        status: RestaurantTableStatus.fromApi(json['status']),
        area: json['area'] is Map
            ? RestaurantArea.fromJson(_map(json['area']))
            : null,
      );
}

class TableSession {
  const TableSession({
    required this.id,
    required this.branchId,
    required this.tableId,
    required this.waiterUserId,
    required this.status,
    required this.dinerCount,
    required this.openedAt,
    required this.orders,
    this.customerName,
    this.notes,
    this.closedAt,
    this.waiterUser,
    this.table,
  });

  final String id;
  final String branchId;
  final String tableId;
  final String waiterUserId;
  final TableSessionStatus status;
  final String? customerName;
  final int dinerCount;
  final String? notes;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final RestaurantUserRef? waiterUser;
  final RestaurantTableRef? table;
  final List<KitchenOrder> orders;

  int get openedMinutes {
    final opened = openedAt;
    if (opened == null) return 0;
    return DateTime.now().difference(opened).inMinutes.clamp(0, 999999);
  }

  double get total => orders
      .where((order) => order.status != KitchenOrderStatus.cancelled)
      .fold(0, (sum, order) => sum + order.total);

  factory TableSession.fromJson(Map<String, Object?> json) => TableSession(
    id: _string(json['id']),
    branchId: _string(json['branchId']),
    tableId: _string(json['tableId']),
    waiterUserId: _string(json['waiterUserId']),
    status: TableSessionStatus.fromApi(json['status']),
    customerName: json['customerName'] as String?,
    dinerCount: _int(json['dinerCount'], fallback: 1),
    notes: json['notes'] as String?,
    openedAt: _date(json['openedAt']),
    closedAt: _date(json['closedAt']),
    waiterUser: json['waiterUser'] is Map
        ? RestaurantUserRef.fromJson(_map(json['waiterUser']))
        : null,
    table: json['table'] is Map
        ? RestaurantTableRef.fromJson(_map(json['table']))
        : null,
    orders: _maps(
      json['orders'],
    ).map(KitchenOrder.fromJson).toList(growable: false),
  );
}

class RestaurantTable {
  const RestaurantTable({
    required this.id,
    required this.branchId,
    required this.number,
    required this.name,
    required this.capacity,
    required this.status,
    required this.sessions,
    this.areaId,
    this.area,
    this.activeSession,
  });

  final String id;
  final String branchId;
  final String? areaId;
  final int number;
  final String name;
  final int capacity;
  final RestaurantTableStatus status;
  final RestaurantArea? area;
  final List<TableSession> sessions;
  final TableSession? activeSession;

  int get guestCount => activeSession?.dinerCount ?? 0;
  String? get waiterName => activeSession?.waiterUser?.fullName;
  int? get openedMinutes => activeSession?.openedMinutes;
  double get total => activeSession?.total ?? 0;

  factory RestaurantTable.fromJson(Map<String, Object?> json) {
    final sessions = _maps(
      json['sessions'],
    ).map(TableSession.fromJson).toList(growable: false);
    final activeSession = json['activeSession'] is Map
        ? TableSession.fromJson(_map(json['activeSession']))
        : sessions.firstOrNull;
    return RestaurantTable(
      id: _string(json['id']),
      branchId: _string(json['branchId']),
      areaId: json['areaId'] as String?,
      number: _int(json['number']),
      name: _string(json['name'], fallback: 'Mesa ${_int(json['number'])}'),
      capacity: _int(json['capacity'], fallback: 1),
      status: RestaurantTableStatus.fromApi(json['status']),
      area: json['area'] is Map
          ? RestaurantArea.fromJson(_map(json['area']))
          : null,
      sessions: sessions,
      activeSession: activeSession,
    );
  }
}

class RestaurantProductRef {
  const RestaurantProductRef({
    required this.id,
    required this.name,
    required this.sku,
  });

  final String id;
  final String name;
  final String sku;

  factory RestaurantProductRef.fromJson(Map<String, Object?> json) =>
      RestaurantProductRef(
        id: _string(json['id']),
        name: _string(json['name'], fallback: 'Producto'),
        sku: _string(json['sku']),
      );
}

class KitchenOrderItem {
  const KitchenOrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.status,
    this.product,
    this.notes,
  });

  final String id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? notes;
  final KitchenItemStatus status;
  final RestaurantProductRef? product;

  String get productName => product?.name ?? 'Producto';

  factory KitchenOrderItem.fromJson(Map<String, Object?> json) =>
      KitchenOrderItem(
        id: _string(json['id']),
        productId: _string(json['productId']),
        quantity: _int(json['quantity']),
        unitPrice: _double(json['unitPrice']),
        lineTotal: _double(json['lineTotal']),
        notes: json['notes'] as String?,
        status: KitchenItemStatus.fromApi(json['status']),
        product: json['product'] is Map
            ? RestaurantProductRef.fromJson(_map(json['product']))
            : null,
      );
}

class KitchenOrder {
  const KitchenOrder({
    required this.id,
    required this.branchId,
    required this.tableSessionId,
    required this.waiterUserId,
    required this.folio,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.tableSession,
    this.waiterUser,
  });

  final String id;
  final String branchId;
  final String tableSessionId;
  final String waiterUserId;
  final String folio;
  final KitchenOrderStatus status;
  final String? notes;
  final TableSession? tableSession;
  final RestaurantUserRef? waiterUser;
  final List<KitchenOrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get total => items
      .where((item) => item.status != KitchenItemStatus.cancelled)
      .fold(0, (sum, item) => sum + item.lineTotal);

  int get elapsedMinutes {
    final created = createdAt;
    if (created == null) return 0;
    return DateTime.now().difference(created).inMinutes.clamp(0, 999999);
  }

  bool get urgent => elapsedMinutes > 20;
  int? get tableNumber => tableSession?.table?.number;
  String get tableLabel => tableNumber == null ? 'Mesa' : 'Mesa $tableNumber';

  factory KitchenOrder.fromJson(Map<String, Object?> json) => KitchenOrder(
    id: _string(json['id']),
    branchId: _string(json['branchId']),
    tableSessionId: _string(json['tableSessionId']),
    waiterUserId: _string(json['waiterUserId']),
    folio: _string(json['folio'], fallback: _string(json['id'])),
    status: KitchenOrderStatus.fromApi(json['status']),
    notes: json['notes'] as String?,
    tableSession: json['tableSession'] is Map
        ? TableSession.fromJson(_map(json['tableSession']))
        : null,
    waiterUser: json['waiterUser'] is Map
        ? RestaurantUserRef.fromJson(_map(json['waiterUser']))
        : null,
    items: _maps(
      json['items'],
    ).map(KitchenOrderItem.fromJson).toList(growable: false),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );
}

Map<String, Object?> _map(Object? value) =>
    value is Map ? value.cast<String, Object?>() : const {};

List<Map<String, Object?>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList(growable: false)
    : const [];

String _string(Object? value, {String fallback = ''}) =>
    value is String && value.isNotEmpty ? value : fallback;

int _int(Object? value, {int fallback = 0}) =>
    (value as num?)?.toInt() ?? fallback;

double _double(Object? value) => (value as num?)?.toDouble() ?? 0;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;
