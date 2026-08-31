enum FittingRoomStatus {
  available,
  occupied,
  needsReview;

  String get apiValue => switch (this) {
    available => 'AVAILABLE',
    occupied => 'OCCUPIED',
    needsReview => 'NEEDS_REVIEW',
  };

  static FittingRoomStatus fromApi(Object? value) => switch (value) {
    'OCCUPIED' => occupied,
    'NEEDS_REVIEW' => needsReview,
    _ => available,
  };
}

enum FittingRoomSessionStatus {
  open,
  closed,
  cancelled;

  String get apiValue => switch (this) {
    open => 'OPEN',
    closed => 'CLOSED',
    cancelled => 'CANCELLED',
  };

  static FittingRoomSessionStatus fromApi(Object? value) => switch (value) {
    'CLOSED' => closed,
    'CANCELLED' => cancelled,
    _ => open,
  };
}

enum FittingSessionItemDisposition {
  pending,
  returnedToFloor,
  sentToPos;

  String get apiValue => switch (this) {
    pending => 'PENDING',
    returnedToFloor => 'RETURNED_TO_FLOOR',
    sentToPos => 'SENT_TO_POS',
  };

  static FittingSessionItemDisposition fromApi(Object? value) => switch (value) {
    'RETURNED_TO_FLOOR' => returnedToFloor,
    'SENT_TO_POS' => sentToPos,
    _ => pending,
  };
}

enum RetailDraftStatus {
  pending,
  consumed,
  cancelled;

  String get apiValue => switch (this) {
    pending => 'PENDING',
    consumed => 'CONSUMED',
    cancelled => 'CANCELLED',
  };

  static RetailDraftStatus fromApi(Object? value) => switch (value) {
    'CONSUMED' => consumed,
    'CANCELLED' => cancelled,
    _ => pending,
  };
}

class OpenFittingRoomSessionRequest {
  const OpenFittingRoomSessionRequest({required this.clientName});
  final String clientName;
  Map<String, Object?> toJson() => {'clientName': clientName.trim()};
}

class AddFittingRoomItemRequest {
  const AddFittingRoomItemRequest({required this.productId, this.quantity = 1});
  final String productId;
  final int quantity;
  Map<String, Object?> toJson() => {'productId': productId, 'quantity': quantity};
}

class FittingRoomCheckoutRequest {
  const FittingRoomCheckoutRequest({
    required this.returnedItemIds,
    required this.saleItemIds,
  });
  final List<String> returnedItemIds;
  final List<String> saleItemIds;
  Map<String, Object?> toJson() => {
        'returnedItemIds': returnedItemIds,
        'saleItemIds': saleItemIds,
      };
}

class RetailUserRef {
  const RetailUserRef({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory RetailUserRef.fromJson(Map<String, Object?> json) => RetailUserRef(
    id: _string(json['id']),
    fullName: _string(json['fullName'], fallback: 'Vendedor'),
    email: _string(json['email']),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
  };
}

class RetailProductRef {
  const RetailProductRef({
    required this.id,
    required this.name,
    required this.sku,
    required this.salePrice,
    this.barcode,
  });

  final String id;
  final String name;
  final String sku;
  final double salePrice;
  final String? barcode;

  factory RetailProductRef.fromJson(Map<String, Object?> json) => RetailProductRef(
    id: _string(json['id']),
    name: _string(json['name'], fallback: 'Producto'),
    sku: _string(json['sku']),
    salePrice: _double(json['salePrice']),
    barcode: json['barcode'] as String?,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'salePrice': salePrice,
    'barcode': barcode,
  };
}

class FittingRoom {
  const FittingRoom({
    required this.id,
    required this.branchId,
    required this.code,
    required this.name,
    required this.status,
    this.activeSession,
  });

  final String id;
  final String branchId;
  final String code;
  final String name;
  final FittingRoomStatus status;
  final FittingRoomSession? activeSession;

  factory FittingRoom.fromJson(Map<String, Object?> json) => FittingRoom(
    id: _string(json['id']),
    branchId: _string(json['branchId']),
    code: _string(json['code']),
    name: _string(json['name'], fallback: 'Probador'),
    status: FittingRoomStatus.fromApi(json['status']),
    activeSession: json['activeSession'] is Map
        ? FittingRoomSession.fromJson(_map(json['activeSession']))
        : null,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'branchId': branchId,
    'code': code,
    'name': name,
    'status': status.apiValue,
    if (activeSession != null) 'activeSession': activeSession!.toJson(),
  };
}

class FittingRoomSession {
  const FittingRoomSession({
    required this.id,
    required this.fittingRoomId,
    required this.sellerId,
    required this.clientName,
    required this.status,
    required this.openedAt,
    this.closedAt,
    required this.items,
    this.seller,
  });

  final String id;
  final String fittingRoomId;
  final String sellerId;
  final String clientName;
  final FittingRoomSessionStatus status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final List<FittingRoomSessionItem> items;
  final RetailUserRef? seller;

  factory FittingRoomSession.fromJson(Map<String, Object?> json) =>
      FittingRoomSession(
        id: _string(json['id']),
        fittingRoomId: _string(json['fittingRoomId']),
        sellerId: _string(json['sellerId']),
        clientName: _string(json['clientName'], fallback: 'Cliente'),
        status: FittingRoomSessionStatus.fromApi(json['status']),
        openedAt: _date(json['openedAt']) ?? DateTime.now(),
        closedAt: _date(json['closedAt']),
        items: _list(json['items'])
            .map((item) => FittingRoomSessionItem.fromJson(_map(item)))
            .toList(),
        seller: json['seller'] is Map
            ? RetailUserRef.fromJson(_map(json['seller']))
            : null,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'fittingRoomId': fittingRoomId,
    'sellerId': sellerId,
    'clientName': clientName,
    'status': status.apiValue,
    'openedAt': openedAt.toIso8601String(),
    if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
    if (seller != null) 'seller': seller!.toJson(),
  };
}

class FittingRoomSessionItem {
  const FittingRoomSessionItem({
    required this.id,
    required this.sessionId,
    required this.productId,
    required this.quantity,
    required this.disposition,
    this.product,
  });

  final String id;
  final String sessionId;
  final String productId;
  final int quantity;
  final FittingSessionItemDisposition disposition;
  final RetailProductRef? product;

  factory FittingRoomSessionItem.fromJson(Map<String, Object?> json) =>
      FittingRoomSessionItem(
        id: _string(json['id']),
        sessionId: _string(json['sessionId']),
        productId: _string(json['productId']),
        quantity: _int(json['quantity'], fallback: 1),
        disposition: FittingSessionItemDisposition.fromApi(json['disposition']),
        product: json['product'] is Map
            ? RetailProductRef.fromJson(_map(json['product']))
            : null,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'productId': productId,
    'quantity': quantity,
    'disposition': disposition.apiValue,
    if (product != null) 'product': product!.toJson(),
  };
}

class RetailDraftItem {
  const RetailDraftItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.sku,
    required this.name,
  });

  final String productId;
  final int quantity;
  final double unitPrice;
  final String sku;
  final String name;

  factory RetailDraftItem.fromJson(Map<String, Object?> json) => RetailDraftItem(
    productId: _string(json['productId']),
    quantity: _int(json['quantity'], fallback: 1),
    unitPrice: _double(json['unitPrice']),
    sku: _string(json['sku']),
    name: _string(json['name'], fallback: 'Producto'),
  );

  Map<String, Object?> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'sku': sku,
    'name': name,
  };
}

class RetailDraft {
  const RetailDraft({
    required this.draftId,
    required this.sessionId,
    required this.clientName,
    required this.sellerId,
    required this.sellerName,
    required this.posCartDraft,
    required this.total,
    required this.status,
    required this.createdAt,
    this.consumedAt,
    this.saleId,
    required this.branchId,
  });

  final String draftId;
  final String sessionId;
  final String clientName;
  final String sellerId;
  final String sellerName;
  final List<RetailDraftItem> posCartDraft;
  final double total;
  final RetailDraftStatus status;
  final DateTime createdAt;
  final DateTime? consumedAt;
  final String? saleId;
  final String branchId;

  factory RetailDraft.fromJson(Map<String, Object?> json) => RetailDraft(
    draftId: _string(json['draftId']),
    sessionId: _string(json['sessionId']),
    clientName: _string(json['clientName'], fallback: 'Cliente'),
    sellerId: _string(json['sellerId']),
    sellerName: _string(json['sellerName'], fallback: 'Vendedor'),
    posCartDraft: _list(json['posCartDraft'])
        .map((item) => RetailDraftItem.fromJson(_map(item)))
        .toList(),
    total: _double(json['total']),
    status: RetailDraftStatus.fromApi(json['status']),
    createdAt: _date(json['createdAt']) ?? DateTime.now(),
    consumedAt: _date(json['consumedAt']),
    saleId: json['saleId'] as String?,
    branchId: _string(json['branchId']),
  );

  Map<String, Object?> toJson() => {
    'draftId': draftId,
    'sessionId': sessionId,
    'clientName': clientName,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'posCartDraft': posCartDraft.map((i) => i.toJson()).toList(),
    'total': total,
    'status': status.apiValue,
    'createdAt': createdAt.toIso8601String(),
    if (consumedAt != null) 'consumedAt': consumedAt!.toIso8601String(),
    if (saleId != null) 'saleId': saleId,
    'branchId': branchId,
  };
}

class CheckoutResult {
  const CheckoutResult({
    required this.session,
    required this.roomId,
    required this.roomStatus,
    this.draftId,
    this.draft,
    required this.posCartDraft,
    this.total,
    required this.message,
  });

  final FittingRoomSession session;
  final String roomId;
  final FittingRoomStatus roomStatus;
  final String? draftId;
  final RetailDraft? draft;
  final List<RetailDraftItem> posCartDraft;
  final double? total;
  final String message;

  factory CheckoutResult.fromJson(Map<String, Object?> json) => CheckoutResult(
    session: FittingRoomSession.fromJson(_map(json['session'])),
    roomId: _string(json['roomId']),
    roomStatus: FittingRoomStatus.fromApi(json['roomStatus']),
    draftId: json['draftId'] as String?,
    draft: json['draft'] is Map
        ? RetailDraft.fromJson(_map(json['draft']))
        : null,
    posCartDraft: _list(json['posCartDraft'])
        .map((item) => RetailDraftItem.fromJson(_map(item)))
        .toList(),
    total: json['total'] == null ? null : _double(json['total']),
    message: _string(json['message'], fallback: 'Liquidación completada'),
  );

  Map<String, Object?> toJson() => {
    'session': session.toJson(),
    'roomId': roomId,
    'roomStatus': roomStatus.apiValue,
    if (draftId != null) 'draftId': draftId,
    if (draft != null) 'draft': draft!.toJson(),
    'posCartDraft': posCartDraft.map((i) => i.toJson()).toList(),
    if (total != null) 'total': total,
    'message': message,
  };
}

// Helpers
String _string(Object? val, {String fallback = ''}) =>
    val is String ? val.trim() : (val?.toString() ?? fallback);

int _int(Object? val, {int fallback = 0}) => (val as num?)?.toInt() ?? fallback;

double _double(Object? val, {double fallback = 0.0}) =>
    (val as num?)?.toDouble() ?? fallback;

DateTime? _date(Object? val) =>
    val is String ? DateTime.tryParse(val)?.toLocal() : null;

Map<String, Object?> _map(Object? val) =>
    val is Map ? val.cast<String, Object?>() : const {};

List<Object?> _list(Object? val) => val is List ? val : const [];
