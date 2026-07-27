enum PurchaseOrderStatus {
  draft,
  pending,
  approved,
  sent,
  partial,
  received,
  cancelled,
}

class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.folio,
    required this.supplier,
    required this.status,
    required this.createdAt,
    required this.expectedDate,
    required this.items,
    required this.total,
    required this.notes,
    required this.createdBy,
  });

  final String id;
  final String folio;
  final String supplier;
  final PurchaseOrderStatus status;
  final DateTime createdAt;
  final DateTime expectedDate;
  final int items;
  final double total;
  final String notes;
  final String createdBy;
}

class Supplier {
  const Supplier({
    required this.id,
    required this.code,
    required this.name,
    required this.rfc,
    required this.contact,
    required this.email,
    required this.phone,
    required this.city,
    required this.categories,
    required this.paymentTerms,
    required this.totalOrders,
    required this.active,
  });

  final String id;
  final String code;
  final String name;
  final String rfc;
  final String contact;
  final String email;
  final String phone;
  final String city;
  final List<String> categories;
  final String paymentTerms;
  final int totalOrders;
  final bool active;
}

class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.sku,
    required this.name,
    required this.unit,
    required this.ordered,
    required this.received,
    required this.cost,
    required this.stockBefore,
    required this.minimum,
  });

  final String sku;
  final String name;
  final String unit;
  final int ordered;
  final int received;
  final double cost;
  final int stockBefore;
  final int minimum;
}
