class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.prepMinutes,
    this.available = true,
    this.popular = false,
  });
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int prepMinutes;
  final bool available;
  final bool popular;
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

  WaiterOrderLine copyWith({int? quantity, String? notes}) => WaiterOrderLine(
    product: product,
    quantity: quantity ?? this.quantity,
    notes: notes ?? this.notes,
  );
}

enum ComandaItemStatus { queued, inPreparation, ready, served }

class ComandaItem {
  const ComandaItem({
    required this.name,
    required this.quantity,
    required this.station,
    required this.status,
    this.notes,
  });
  final String name;
  final int quantity;
  final String station;
  final ComandaItemStatus status;
  final String? notes;
}
