enum ProductStatus { active, inactive, discontinued }

class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.cost,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.status,
  });

  final String id;
  final String sku;
  final String name;
  final String category;
  final String unit;
  final double cost;
  final double price;
  final int stock;
  final int minStock;
  final ProductStatus status;
}

class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.productCount,
    required this.colorValue,
    required this.subcategories,
  });

  final String id;
  final String name;
  final String description;
  final int productCount;
  final int colorValue;
  final List<String> subcategories;
}

enum StockSeverity { outOfStock, critical, low, ok }

class StockAlert {
  const StockAlert({
    required this.id,
    required this.product,
    required this.maxStock,
    required this.severity,
    required this.lastMovement,
    required this.suggestedOrder,
  });

  final String id;
  final Product product;
  final int maxStock;
  final StockSeverity severity;
  final String lastMovement;
  final int suggestedOrder;
}
