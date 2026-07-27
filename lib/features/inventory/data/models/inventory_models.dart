enum ProductStatus { active, inactive }

class ProductImage {
  const ProductImage({
    required this.id,
    required this.url,
    this.altText,
    required this.sortOrder,
    required this.isPrimary,
  });

  final String id;
  final String url;
  final String? altText;
  final int sortOrder;
  final bool isPrimary;

  Map<String, Object?> toPreserveJson() => {
    'id': id,
    'altText': altText,
    'sortOrder': sortOrder,
    'isPrimary': isPrimary,
  };

  factory ProductImage.fromJson(Map<String, Object?> json) => ProductImage(
    id: json['id']! as String,
    url: json['url']! as String,
    altText: json['altText'] as String?,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    isPrimary: json['isPrimary'] as bool? ?? false,
  );
}

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.cost,
    required this.price,
    required this.status,
    this.description,
    this.barcode,
    this.images = const [],
  });

  final String id;
  final String sku;
  final String name;
  final String categoryId;
  final String categoryName;
  final String unit;
  final double cost;
  final double price;
  final ProductStatus status;
  final String? description;
  final String? barcode;
  final List<ProductImage> images;

  bool get isActive => status == ProductStatus.active;
  ProductImage? get primaryImage =>
      images.where((image) => image.isPrimary).firstOrNull ??
      images.firstOrNull;

  factory Product.fromJson(Map<String, Object?> json) {
    final category = _mapOrEmpty(json['category']);
    return Product(
      id: json['id']! as String,
      sku: json['sku']! as String,
      name: json['name']! as String,
      categoryId:
          json['categoryId'] as String? ?? category['id'] as String? ?? '',
      categoryName: category['name'] as String? ?? 'Sin categoría',
      unit: json['unitName'] as String? ?? 'pieza',
      cost: (json['costPrice'] as num?)?.toDouble() ?? 0,
      price: (json['salePrice'] as num?)?.toDouble() ?? 0,
      status: json['status'] == 'INACTIVE'
          ? ProductStatus.inactive
          : ProductStatus.active,
      description: json['description'] as String?,
      barcode: json['barcode'] as String?,
      images: _mapList(
        json['images'],
      ).map(ProductImage.fromJson).toList(growable: false),
    );
  }
}

class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String name;
  final String code;
  final String description;
  final bool isActive;

  factory InventoryCategory.fromJson(Map<String, Object?> json) =>
      InventoryCategory(
        id: json['id']! as String,
        name: json['name']! as String,
        code: json['code']! as String,
        description: json['description'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );
}

enum StockSeverity { outOfStock, low, ok }

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.productStatus,
    required this.salePrice,
    required this.stockOnHand,
    required this.reservedStock,
    required this.availableStock,
    required this.minStock,
    required this.alertLevel,
    this.barcode,
  });

  final String id;
  final String branchId;
  final String productId;
  final String productName;
  final String sku;
  final String? barcode;
  final String productStatus;
  final double salePrice;
  final int stockOnHand;
  final int reservedStock;
  final int availableStock;
  final int minStock;
  final String alertLevel;

  bool get isLowStock => alertLevel == 'RED' || alertLevel == 'ORANGE';
  StockSeverity get severity => stockOnHand <= 0
      ? StockSeverity.outOfStock
      : isLowStock
      ? StockSeverity.low
      : StockSeverity.ok;

  factory InventoryItem.fromJson(Map<String, Object?> json) {
    final product = _mapOrEmpty(json['product']);
    final stockOnHand = (json['stockOnHand'] as num?)?.toInt() ?? 0;
    final minStock = (json['minStock'] as num?)?.toInt() ?? 0;
    final fallbackLevel = stockOnHand <= 0
        ? 'RED'
        : minStock > 0 && stockOnHand <= minStock
        ? 'ORANGE'
        : 'OK';
    return InventoryItem(
      id: json['id']! as String,
      branchId: json['branchId']! as String,
      productId: json['productId']! as String,
      productName: product['name'] as String? ?? 'Producto',
      sku: product['sku'] as String? ?? '',
      barcode: product['barcode'] as String?,
      productStatus: product['status'] as String? ?? 'ACTIVE',
      salePrice: (product['salePrice'] as num?)?.toDouble() ?? 0,
      stockOnHand: stockOnHand,
      reservedStock: (json['reservedStock'] as num?)?.toInt() ?? 0,
      availableStock: (json['availableStock'] as num?)?.toInt() ?? stockOnHand,
      minStock: minStock,
      alertLevel: json['alertLevel'] as String? ?? fallbackLevel,
    );
  }
}

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.type,
    required this.quantityDelta,
    required this.stockBefore,
    required this.stockAfter,
    required this.createdAt,
    this.notes,
    this.actorUserId,
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String type;
  final int quantityDelta;
  final int stockBefore;
  final int stockAfter;
  final String? notes;
  final String? actorUserId;
  final DateTime createdAt;

  factory InventoryMovement.fromJson(Map<String, Object?> json) {
    final product = _mapOrEmpty(json['product']);
    return InventoryMovement(
      id: json['id']! as String,
      productId: json['productId']! as String,
      productName: product['name'] as String? ?? 'Producto',
      sku: product['sku'] as String? ?? '',
      type: json['movementType']! as String,
      quantityDelta: (json['quantityDelta'] as num?)?.toInt() ?? 0,
      stockBefore: (json['stockBefore'] as num?)?.toInt() ?? 0,
      stockAfter: (json['stockAfter'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      actorUserId: json['actorUserId'] as String?,
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }
}

List<Map<String, Object?>> _mapList(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => item.cast<String, Object?>())
          .toList(growable: false)
    : const [];

Map<String, Object?> _mapOrEmpty(Object? value) =>
    value is Map ? value.cast<String, Object?>() : const {};
