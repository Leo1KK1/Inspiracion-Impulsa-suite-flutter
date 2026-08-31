enum CashShiftStatus {
  open,
  closed;

  static CashShiftStatus fromApi(String? value) =>
      value == 'OPEN' ? open : closed;
}

enum SaleStatus {
  completed,
  pending,
  cancelled,
  refunded,
  unknown;

  static SaleStatus fromApi(String? value) => switch (value) {
    'COMPLETED' => completed,
    'PENDING' => pending,
    'CANCELLED' => cancelled,
    'REFUNDED' => refunded,
    _ => unknown,
  };
}

enum PaymentStatus {
  completed,
  pending,
  failed,
  refunded,
  unknown;

  static PaymentStatus fromApi(String? value) => switch (value) {
    'COMPLETED' => completed,
    'PENDING' => pending,
    'FAILED' => failed,
    'REFUNDED' => refunded,
    _ => unknown,
  };
}

enum PaymentMethod {
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

  static PaymentMethod fromApi(String? value) => switch (value) {
    'CARD' => card,
    'MIXED' => mixed,
    _ => cash,
  };
}

class PosProduct {
  const PosProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.salePrice,
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
  final double salePrice;
  final String unitName;
  final String? categoryId;
  final String category;
  final int stockOnHand;
  final int availableStock;
  final String? imageUrl;
  final int? minStock;
  final bool isLowStock;

  double get price => salePrice;
  int get stock => availableStock;

  factory PosProduct.fromJson(Map<String, Object?> json) {
    final category = _mapOrEmpty(json['category']);
    return PosProduct(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Producto',
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String?,
      salePrice: _double(json['salePrice']),
      unitName: json['unitName'] as String? ?? 'pieza',
      categoryId: category['id'] as String?,
      category: category['name'] as String? ?? 'Sin categoría',
      stockOnHand: _int(json['stockOnHand']),
      availableStock: _int(json['availableStock']),
      imageUrl: json['imageUrl'] as String?,
      minStock: json['minStock'] == null ? null : _int(json['minStock']),
      isLowStock: json['isLowStock'] as bool? ?? false,
    );
  }
}

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.discount = 0,
  });

  final PosProduct product;
  final int quantity;
  final double discount;

  double get subtotal => product.salePrice * quantity;
  double get discountAmount => subtotal * discount / 100;
  double get total => subtotal - discountAmount;

  CartLine copyWith({int? quantity, double? discount}) => CartLine(
    product: product,
    quantity: quantity ?? this.quantity,
    discount: discount ?? this.discount,
  );

  Map<String, Object?> toSaleJson() => {
    'productId': product.id,
    'quantity': quantity,
    'unitPrice': product.salePrice,
    'discount': discount,
  };
}

class CashShift {
  const CashShift({
    required this.id,
    required this.branchId,
    required this.cashierId,
    required this.status,
    required this.openingAmount,
    required this.totalSales,
    required this.totalCash,
    required this.totalCard,
    required this.salesCount,
    required this.openedAt,
    this.closingAmount,
    this.notes,
    this.closedAt,
    this.difference,
  });

  final String id;
  final String branchId;
  final String cashierId;
  final CashShiftStatus status;
  final double openingAmount;
  final double? closingAmount;
  final double totalSales;
  final double totalCash;
  final double totalCard;
  final int salesCount;
  final String? notes;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final double? difference;

  bool get isOpen => status == CashShiftStatus.open;

  factory CashShift.fromJson(Map<String, Object?> json) => CashShift(
    id: json['id'] as String? ?? '',
    branchId: json['branchId'] as String? ?? '',
    cashierId: json['cashierId'] as String? ?? '',
    status: CashShiftStatus.fromApi(json['status'] as String?),
    openingAmount: _double(json['openingAmount']),
    closingAmount: _nullableDouble(json['closingAmount']),
    totalSales: _double(json['totalSales']),
    totalCash: _double(json['totalCash']),
    totalCard: _double(json['totalCard']),
    salesCount: _int(json['salesCount']),
    notes: json['notes'] as String?,
    openedAt: _date(json['openedAt']),
    closedAt: _date(json['closedAt']),
    difference: _nullableDouble(json['difference']),
  );
}

class CashMovement {
  const CashMovement({
    required this.type,
    required this.amount,
    required this.createdAt,
    this.notes,
  });

  final String type;
  final double amount;
  final String? notes;
  final DateTime? createdAt;

  factory CashMovement.fromJson(Map<String, Object?> json) => CashMovement(
    type: json['type'] as String? ?? '',
    amount: _double(json['amount']),
    notes: json['notes'] as String?,
    createdAt: _date(json['createdAt']),
  );
}

class CashShiftSummary {
  const CashShiftSummary({
    required this.shift,
    required this.salesCount,
    required this.totalSales,
    required this.totalCash,
    required this.totalCard,
    required this.cashMovements,
    this.difference,
  });

  final CashShift shift;
  final int salesCount;
  final double totalSales;
  final double totalCash;
  final double totalCard;
  final double? difference;
  final List<CashMovement> cashMovements;

  factory CashShiftSummary.fromJson(Map<String, Object?> json) {
    final summary = _mapOrEmpty(json['summary']);
    return CashShiftSummary(
      shift: CashShift.fromJson(_mapOrEmpty(json['shift'])),
      salesCount: _int(summary['salesCount']),
      totalSales: _double(summary['totalSales']),
      totalCash: _double(summary['totalCash']),
      totalCard: _double(summary['totalCard']),
      difference: _nullableDouble(summary['difference']),
      cashMovements: _maps(
        json['cashMovements'],
      ).map(CashMovement.fromJson).toList(growable: false),
    );
  }
}

class PosSaleItem {
  const PosSaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.lineTotal,
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double lineTotal;

  factory PosSaleItem.fromJson(Map<String, Object?> json) {
    final product = _mapOrEmpty(json['product']);
    return PosSaleItem(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productName: product['name'] as String? ?? 'Producto',
      sku: product['sku'] as String? ?? '',
      quantity: _int(json['quantity']),
      unitPrice: _double(json['unitPrice']),
      discount: _double(json['discount']),
      lineTotal: _double(json['lineTotal']),
    );
  }
}

class PosPayment {
  const PosPayment({
    required this.id,
    required this.method,
    required this.amount,
    required this.status,
    this.cashReceived,
    this.changeGiven,
    this.gatewayProvider,
    this.gatewayIntentId,
    this.gatewayRef,
    this.processedAt,
  });

  final String id;
  final PaymentMethod method;
  final double amount;
  final double? cashReceived;
  final double? changeGiven;
  final PaymentStatus status;
  final String? gatewayProvider;
  final String? gatewayIntentId;
  final String? gatewayRef;
  final DateTime? processedAt;

  factory PosPayment.fromJson(Map<String, Object?> json) => PosPayment(
    id: json['id'] as String? ?? '',
    method: PaymentMethod.fromApi(json['paymentMethod'] as String?),
    amount: _double(json['amount']),
    cashReceived: _nullableDouble(json['cashReceived']),
    changeGiven: _nullableDouble(json['changeGiven']),
    status: PaymentStatus.fromApi(json['status'] as String?),
    gatewayProvider: json['gatewayProvider'] as String?,
    gatewayIntentId: json['gatewayIntentId'] as String?,
    gatewayRef: json['gatewayRef'] as String?,
    processedAt: _date(json['processedAt']),
  );
}

class CardPaymentIntent {
  const CardPaymentIntent({
    required this.intentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.gatewayProvider,
    this.saleId,
    this.expiresAt,
  });

  final String intentId;
  final String? saleId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String gatewayProvider;
  final DateTime? expiresAt;

  bool get isLocalDevelopment => gatewayProvider == 'MOCK_LOCAL';

  factory CardPaymentIntent.fromJson(Map<String, Object?> json) =>
      CardPaymentIntent(
        intentId: json['intentId'] as String? ?? '',
        saleId: json['saleId'] as String?,
        amount: _double(json['amount']),
        currency: json['currency'] as String? ?? 'MXN',
        status: PaymentStatus.fromApi(json['status'] as String?),
        gatewayProvider: json['gatewayProvider'] as String? ?? 'UNKNOWN',
        expiresAt: _date(json['expiresAt']),
      );

  factory CardPaymentIntent.fromPayment(
    PosPayment payment, {
    required String saleId,
  }) => CardPaymentIntent(
    intentId: payment.gatewayIntentId ?? '',
    saleId: saleId,
    amount: payment.amount,
    currency: 'MXN',
    status: payment.status,
    gatewayProvider: payment.gatewayProvider ?? 'UNKNOWN',
  );
}

class PosSale {
  const PosSale({
    required this.id,
    required this.branchId,
    required this.cashShiftId,
    required this.cashierId,
    required this.folio,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.payments,
    required this.createdAt,
    this.notes,
    this.cashReceived,
    this.changeGiven,
    this.cardPaymentIntent,
  });

  final String id;
  final String branchId;
  final String cashShiftId;
  final String cashierId;
  final String folio;
  final double subtotal;
  final double discountAmount;
  final double total;
  final SaleStatus status;
  final String? notes;
  final PaymentMethod paymentMethod;
  final double? cashReceived;
  final double? changeGiven;
  final PaymentStatus paymentStatus;
  final List<PosSaleItem> items;
  final List<PosPayment> payments;
  final DateTime? createdAt;
  final CardPaymentIntent? cardPaymentIntent;

  PosPayment? get pendingCardPayment {
    for (final payment in payments) {
      if (payment.method == PaymentMethod.card &&
          payment.status == PaymentStatus.pending) {
        return payment;
      }
    }
    return null;
  }

  factory PosSale.fromJson(Map<String, Object?> json) => PosSale(
    id: json['id'] as String? ?? '',
    branchId: json['branchId'] as String? ?? '',
    cashShiftId: json['cashShiftId'] as String? ?? '',
    cashierId: json['cashierId'] as String? ?? '',
    folio: json['folio'] as String? ?? '',
    subtotal: _double(json['subtotal']),
    discountAmount: _double(json['discountAmount']),
    total: _double(json['total']),
    status: SaleStatus.fromApi(json['status'] as String?),
    notes: json['notes'] as String?,
    paymentMethod: PaymentMethod.fromApi(json['paymentMethod'] as String?),
    cashReceived: _nullableDouble(json['cashReceived']),
    changeGiven: _nullableDouble(json['changeGiven']),
    paymentStatus: PaymentStatus.fromApi(json['paymentStatus'] as String?),
    items: _maps(
      json['items'],
    ).map(PosSaleItem.fromJson).toList(growable: false),
    payments: _maps(
      json['payments'],
    ).map(PosPayment.fromJson).toList(growable: false),
    createdAt: _date(json['createdAt']),
    cardPaymentIntent: json['cardPaymentIntent'] is Map
        ? CardPaymentIntent.fromJson(_mapOrEmpty(json['cardPaymentIntent']))
        : null,
  );
}

typedef PosTicket = PosSale;

class CreatePosSaleRequest {
  const CreatePosSaleRequest({
    required this.cashShiftId,
    required this.items,
    required this.paymentMethod,
    this.cashReceived,
    this.notes,
    this.retailDraftId,
    this.consumeReservedStock,
  });

  final String cashShiftId;
  final List<CartLine> items;
  final PaymentMethod paymentMethod;
  final double? cashReceived;
  final String? notes;
  final String? retailDraftId;
  final bool? consumeReservedStock;

  Map<String, Object?> toJson() => {
    'cashShiftId': cashShiftId,
    'items': items.map((item) => item.toSaleJson()).toList(growable: false),
    'paymentMethod': paymentMethod.apiValue,
    if (cashReceived != null) 'cashReceived': cashReceived,
    if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
    if (retailDraftId != null) 'retailDraftId': retailDraftId,
    if (consumeReservedStock != null) 'consumeReservedStock': consumeReservedStock,
  };
}

Map<String, Object?> _mapOrEmpty(Object? value) =>
    value is Map ? value.cast<String, Object?>() : const {};

List<Map<String, Object?>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList(growable: false)
    : const [];

double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
double? _nullableDouble(Object? value) => (value as num?)?.toDouble();
int _int(Object? value) => (value as num?)?.toInt() ?? 0;
DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;
