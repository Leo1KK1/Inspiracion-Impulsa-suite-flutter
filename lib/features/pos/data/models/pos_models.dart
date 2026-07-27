class PosProduct {
  const PosProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.stock,
    this.popular = false,
  });

  final String id;
  final String name;
  final double price;
  final String category;
  final int stock;
  final bool popular;
}

class CartLine {
  const CartLine({required this.product, required this.quantity});
  final PosProduct product;
  final int quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}

enum TicketStatus { completed, cancelled, refunded }

enum PaymentMethod { cash, card, transfer }

class PosTicket {
  const PosTicket({
    required this.id,
    required this.folio,
    required this.time,
    required this.status,
    required this.method,
    required this.total,
    required this.cashier,
    required this.lines,
  });

  final String id;
  final String folio;
  final String time;
  final TicketStatus status;
  final PaymentMethod method;
  final double total;
  final String cashier;
  final List<CartLine> lines;
}
