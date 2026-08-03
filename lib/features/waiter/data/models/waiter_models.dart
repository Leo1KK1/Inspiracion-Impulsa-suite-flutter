import '../../../restaurant_floor/data/models/restaurant_models.dart';

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.unitName,
    required this.category,
    required this.stockOnHand,
    required this.availableStock,
    this.barcode,
    this.categoryId,
    this.imageUrl,
    this.minStock,
    this.isLowStock = false,
  });

  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final double price;
  final String unitName;
  final String? categoryId;
  final String category;
  final int stockOnHand;
  final int availableStock;
  final String? imageUrl;
  final int? minStock;
  final bool isLowStock;

  bool get available => availableStock > 0;

  factory MenuProduct.fromJson(Map<String, Object?> json) {
    final category = _map(json['category']);
    return MenuProduct(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Producto'),
      sku: _string(json['sku']),
      barcode: json['barcode'] as String?,
      price: _double(json['salePrice']),
      unitName: _string(json['unitName'], fallback: 'pieza'),
      categoryId: category['id'] as String?,
      category: _string(category['name'], fallback: 'Sin categoría'),
      stockOnHand: _int(json['stockOnHand']),
      availableStock: _int(json['availableStock']),
      imageUrl: json['imageUrl'] as String?,
      minStock: json['minStock'] == null ? null : _int(json['minStock']),
      isLowStock: json['isLowStock'] as bool? ?? false,
    );
  }
}

class WaiterOrderLine {
  const WaiterOrderLine({
    required this.product,
    required this.quantity,
    this.notes = '',
  });

  final MenuProduct product;
  final int quantity;
  final String notes;

  double get total => product.price * quantity;

  WaiterOrderLine copyWith({
    MenuProduct? product,
    int? quantity,
    String? notes,
  }) => WaiterOrderLine(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
    notes: notes ?? this.notes,
  );

  Map<String, Object?> toJson() => {
    'productId': product.id,
    'quantity': quantity,
    'unitPrice': product.price,
    if (notes.trim().isNotEmpty) 'notes': notes.trim(),
  };
}

class OpenTableSessionRequest {
  const OpenTableSessionRequest({
    required this.dinerCount,
    this.waiterUserId,
    this.customerName,
    this.notes,
  });

  final String? waiterUserId;
  final String? customerName;
  final int dinerCount;
  final String? notes;

  Map<String, Object?> toJson() => {
    if (waiterUserId?.trim().isNotEmpty == true)
      'waiterUserId': waiterUserId!.trim(),
    if (customerName?.trim().isNotEmpty == true)
      'customerName': customerName!.trim(),
    'dinerCount': dinerCount,
    if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
  };
}

enum SplitBillMode {
  equal,
  byItem;

  String get apiValue => this == equal ? 'EQUAL' : 'BY_ITEM';
}

class SplitBillAssignment {
  const SplitBillAssignment({required this.guestLabel, required this.itemIds});

  final String guestLabel;
  final List<String> itemIds;

  Map<String, Object?> toJson() => {
    'guestLabel': guestLabel,
    'itemIds': itemIds,
  };
}

class BillableItem {
  const BillableItem({
    required this.itemId,
    required this.orderId,
    required this.folio,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.notes,
  });

  final String itemId;
  final String orderId;
  final String folio;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? notes;

  factory BillableItem.fromJson(Map<String, Object?> json) => BillableItem(
    itemId: _string(json['itemId']),
    orderId: _string(json['orderId']),
    folio: _string(json['folio']),
    productId: _string(json['productId']),
    productName: _string(json['productName'], fallback: 'Producto'),
    quantity: _int(json['quantity']),
    unitPrice: _double(json['unitPrice']),
    lineTotal: _double(json['lineTotal']),
    notes: json['notes'] as String?,
  );
}

class EqualBillPart {
  const EqualBillPart({required this.part, required this.amount});

  final int part;
  final double amount;

  factory EqualBillPart.fromJson(Map<String, Object?> json) =>
      EqualBillPart(part: _int(json['part']), amount: _double(json['amount']));
}

class ItemBillGroup {
  const ItemBillGroup({
    required this.guestLabel,
    required this.amount,
    required this.items,
  });

  final String guestLabel;
  final double amount;
  final List<BillableItem> items;

  factory ItemBillGroup.fromJson(Map<String, Object?> json) => ItemBillGroup(
    guestLabel: _string(json['guestLabel']),
    amount: _double(json['amount']),
    items: _maps(
      json['items'],
    ).map(BillableItem.fromJson).toList(growable: false),
  );
}

class SplitBillResult {
  const SplitBillResult({
    required this.mode,
    required this.tableId,
    required this.sessionId,
    required this.grandTotal,
    required this.parts,
    required this.groups,
    required this.items,
    required this.unassignedItems,
    this.assignedTotal,
  });

  final SplitBillMode mode;
  final String tableId;
  final String sessionId;
  final double grandTotal;
  final double? assignedTotal;
  final List<EqualBillPart> parts;
  final List<ItemBillGroup> groups;
  final List<BillableItem> items;
  final List<BillableItem> unassignedItems;

  factory SplitBillResult.fromJson(Map<String, Object?> json) =>
      SplitBillResult(
        mode: json['mode'] == 'BY_ITEM'
            ? SplitBillMode.byItem
            : SplitBillMode.equal,
        tableId: _string(json['tableId']),
        sessionId: _string(json['sessionId']),
        grandTotal: _double(json['grandTotal']),
        assignedTotal: json['assignedTotal'] == null
            ? null
            : _double(json['assignedTotal']),
        parts: _maps(
          json['parts'],
        ).map(EqualBillPart.fromJson).toList(growable: false),
        groups: _maps(
          json['groups'],
        ).map(ItemBillGroup.fromJson).toList(growable: false),
        items: _maps(
          json['items'],
        ).map(BillableItem.fromJson).toList(growable: false),
        unassignedItems: _maps(
          json['unassignedItems'],
        ).map(BillableItem.fromJson).toList(growable: false),
      );
}

enum RestaurantPaymentMethod {
  cash,
  card,
  mixed;

  String get apiValue => switch (this) {
    cash => 'CASH',
    card => 'CARD',
    mixed => 'MIXED',
  };

  String get label => switch (this) {
    cash => 'Efectivo',
    card => 'Tarjeta',
    mixed => 'Mixto',
  };
}

class RestaurantCheckoutRequest {
  const RestaurantCheckoutRequest({
    required this.cashShiftId,
    required this.paymentMethod,
    required this.nextTableStatus,
    this.cashReceived,
    this.notes,
  });

  final String cashShiftId;
  final RestaurantPaymentMethod paymentMethod;
  final double? cashReceived;
  final RestaurantTableStatus nextTableStatus;
  final String? notes;

  Map<String, Object?> toJson() => {
    'cashShiftId': cashShiftId,
    'paymentMethod': paymentMethod.apiValue,
    if (cashReceived != null) 'cashReceived': cashReceived,
    'nextTableStatus': nextTableStatus.apiValue,
    if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
  };
}

class RestaurantSaleSummary {
  const RestaurantSaleSummary({
    required this.id,
    required this.folio,
    required this.total,
    this.tableSessionId,
  });

  final String id;
  final String folio;
  final double total;
  final String? tableSessionId;

  factory RestaurantSaleSummary.fromJson(Map<String, Object?> json) =>
      RestaurantSaleSummary(
        id: _string(json['id']),
        folio: _string(json['folio']),
        total: _double(json['total']),
        tableSessionId: json['tableSessionId'] as String?,
      );
}

class RestaurantCardIntent {
  const RestaurantCardIntent({
    required this.intentId,
    required this.status,
    required this.gatewayProvider,
    required this.amount,
  });

  final String intentId;
  final String status;
  final String gatewayProvider;
  final double amount;

  factory RestaurantCardIntent.fromJson(Map<String, Object?> json) =>
      RestaurantCardIntent(
        intentId: _string(json['intentId']),
        status: _string(json['status']),
        gatewayProvider: _string(json['gatewayProvider']),
        amount: _double(json['amount']),
      );
}

class RestaurantCheckoutResult {
  const RestaurantCheckoutResult({
    required this.sale,
    required this.session,
    required this.tableStatus,
    required this.message,
    this.cardPaymentIntent,
  });

  final RestaurantSaleSummary sale;
  final RestaurantCardIntent? cardPaymentIntent;
  final TableSession session;
  final RestaurantTableStatus tableStatus;
  final String message;

  factory RestaurantCheckoutResult.fromJson(Map<String, Object?> json) =>
      RestaurantCheckoutResult(
        sale: RestaurantSaleSummary.fromJson(_map(json['sale'])),
        cardPaymentIntent: json['cardPaymentIntent'] is Map
            ? RestaurantCardIntent.fromJson(_map(json['cardPaymentIntent']))
            : null,
        session: TableSession.fromJson(_map(json['session'])),
        tableStatus: RestaurantTableStatus.fromApi(json['tableStatus']),
        message: _string(
          json['message'],
          fallback: 'Checkout completado correctamente.',
        ),
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

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
