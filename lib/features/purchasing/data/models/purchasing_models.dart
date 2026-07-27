enum PurchaseOrderStatus {
  draft,
  submitted,
  partiallyReceived,
  received,
  cancelled;

  String get apiValue => switch (this) {
    draft => 'DRAFT',
    submitted => 'SUBMITTED',
    partiallyReceived => 'PARTIALLY_RECEIVED',
    received => 'RECEIVED',
    cancelled => 'CANCELLED',
  };

  static PurchaseOrderStatus fromApi(String value) => switch (value) {
    'SUBMITTED' => submitted,
    'PARTIALLY_RECEIVED' => partiallyReceived,
    'RECEIVED' => received,
    'CANCELLED' => cancelled,
    _ => draft,
  };
}

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.active,
    this.taxId,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.address,
  });

  final String id;
  final String name;
  final bool active;
  final String? taxId;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;

  factory Supplier.fromJson(Map<String, Object?> json) => Supplier(
    id: json['id']! as String,
    name: json['name']! as String,
    active: json['isActive'] as bool? ?? true,
    taxId: json['taxId'] as String?,
    contactName: json['contactName'] as String?,
    contactEmail: json['contactEmail'] as String?,
    contactPhone: json['contactPhone'] as String?,
    address: json['address'] as String?,
  );
}

class PurchaseOrderItem {
  const PurchaseOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.unitCost,
    required this.lineTotal,
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final int quantityOrdered;
  final int quantityReceived;
  final double unitCost;
  final double lineTotal;

  int get pending => quantityOrdered - quantityReceived;

  factory PurchaseOrderItem.fromJson(Map<String, Object?> json) {
    final product = _mapOrEmpty(json['product']);
    final quantity = (json['quantityOrdered'] as num?)?.toInt() ?? 0;
    final cost = (json['unitCost'] as num?)?.toDouble() ?? 0;
    return PurchaseOrderItem(
      id: json['id']! as String,
      productId: json['productId'] as String? ?? product['id'] as String? ?? '',
      productName: product['name'] as String? ?? 'Producto',
      sku: product['sku'] as String? ?? '',
      quantityOrdered: quantity,
      quantityReceived: (json['quantityReceived'] as num?)?.toInt() ?? 0,
      unitCost: cost,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? quantity * cost,
    );
  }
}

class PurchaseReceipt {
  const PurchaseReceipt({
    required this.id,
    required this.number,
    required this.receivedAt,
    required this.items,
    this.notes,
  });

  final String id;
  final String number;
  final DateTime receivedAt;
  final String? notes;
  final List<Map<String, Object?>> items;

  factory PurchaseReceipt.fromJson(Map<String, Object?> json) =>
      PurchaseReceipt(
        id: json['id']! as String,
        number: json['receiptNumber']! as String,
        receivedAt: DateTime.parse(json['receivedAt']! as String),
        notes: json['notes'] as String?,
        items: _mapList(json['items']),
      );
}

class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.folio,
    required this.supplierId,
    required this.supplier,
    required this.branchId,
    required this.branchName,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.receipts,
    this.reportedItemsCount = 0,
    this.notes,
    this.submittedAt,
    this.receivedAt,
  });

  final String id;
  final String folio;
  final String supplierId;
  final String supplier;
  final String branchId;
  final String branchName;
  final PurchaseOrderStatus status;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? receivedAt;
  final List<PurchaseOrderItem> items;
  final double subtotal;
  final double total;
  final String? notes;
  final List<PurchaseReceipt> receipts;
  final int reportedItemsCount;

  int get itemsCount => items.isEmpty ? reportedItemsCount : items.length;
  bool get canEdit => status == PurchaseOrderStatus.draft;
  bool get canSubmit => status == PurchaseOrderStatus.draft;
  bool get canReceive =>
      status == PurchaseOrderStatus.submitted ||
      status == PurchaseOrderStatus.partiallyReceived;
  bool get canCancel =>
      status == PurchaseOrderStatus.draft ||
      status == PurchaseOrderStatus.submitted;

  factory PurchaseOrder.fromJson(Map<String, Object?> json) {
    final supplier = _mapOrEmpty(json['supplier']);
    final branch = _mapOrEmpty(json['branch']);
    return PurchaseOrder(
      id: json['id']! as String,
      folio: json['folio']! as String,
      supplierId:
          json['supplierId'] as String? ?? supplier['id'] as String? ?? '',
      supplier: supplier['name'] as String? ?? 'Proveedor',
      branchId: json['branchId']! as String,
      branchName: branch['name'] as String? ?? '',
      status: PurchaseOrderStatus.fromApi(json['status']! as String),
      createdAt: DateTime.parse(json['createdAt']! as String),
      submittedAt: _date(json['submittedAt']),
      receivedAt: _date(json['receivedAt']),
      items: _mapList(
        json['items'],
      ).map(PurchaseOrderItem.fromJson).toList(growable: false),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      receipts: _mapList(
        json['receipts'],
      ).map(PurchaseReceipt.fromJson).toList(growable: false),
      reportedItemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
Map<String, Object?> _mapOrEmpty(Object? value) =>
    value is Map ? value.cast<String, Object?>() : const {};
List<Map<String, Object?>> _mapList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList(growable: false)
    : const [];
