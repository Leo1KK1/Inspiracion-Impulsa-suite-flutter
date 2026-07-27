import '../models/pos_models.dart';

abstract interface class PosRepository {
  Future<List<PosProduct>> getProducts({String? branchId});
  Future<List<PosTicket>> getTickets({String? branchId});
}

class MockPosRepository implements PosRepository {
  static const products = [
    PosProduct(
      id: 'p01',
      name: 'Coca-Cola 600ml',
      price: 25,
      category: 'Bebidas',
      stock: 142,
      popular: true,
    ),
    PosProduct(
      id: 'p02',
      name: 'Agua natural 1L',
      price: 18,
      category: 'Bebidas',
      stock: 98,
    ),
    PosProduct(
      id: 'p03',
      name: 'Cerveza Modelo 355ml',
      price: 45,
      category: 'Bebidas',
      stock: 60,
      popular: true,
    ),
    PosProduct(
      id: 'p04',
      name: 'Jugo naranja 500ml',
      price: 30,
      category: 'Bebidas',
      stock: 34,
    ),
    PosProduct(
      id: 'p05',
      name: 'Café americano',
      price: 35,
      category: 'Bebidas',
      stock: 999,
    ),
    PosProduct(
      id: 'p06',
      name: 'Tacos de canasta x3',
      price: 55,
      category: 'Alimentos',
      stock: 45,
      popular: true,
    ),
    PosProduct(
      id: 'p07',
      name: 'Torta de jamón',
      price: 70,
      category: 'Alimentos',
      stock: 22,
    ),
    PosProduct(
      id: 'p08',
      name: 'Ensalada César',
      price: 95,
      category: 'Alimentos',
      stock: 18,
    ),
    PosProduct(
      id: 'p09',
      name: 'Orden de papas',
      price: 50,
      category: 'Alimentos',
      stock: 30,
      popular: true,
    ),
    PosProduct(
      id: 'p10',
      name: 'Sandwich club',
      price: 85,
      category: 'Alimentos',
      stock: 14,
    ),
    PosProduct(
      id: 'p11',
      name: 'Coctel de frutas',
      price: 40,
      category: 'Postres',
      stock: 20,
    ),
    PosProduct(
      id: 'p12',
      name: 'Flan napolitano',
      price: 45,
      category: 'Postres',
      stock: 12,
    ),
  ];

  @override
  Future<List<PosProduct>> getProducts({String? branchId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return products;
  }

  @override
  Future<List<PosTicket>> getTickets({String? branchId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return [
      PosTicket(
        id: 't01',
        folio: 'T-0041',
        time: '18:32',
        status: TicketStatus.completed,
        method: PaymentMethod.cash,
        total: 179.80,
        cashier: 'M. López',
        lines: [
          CartLine(product: products[0], quantity: 2),
          CartLine(product: products[5], quantity: 1),
          CartLine(product: products[8], quantity: 1),
        ],
      ),
      PosTicket(
        id: 't02',
        folio: 'T-0040',
        time: '18:15',
        status: TicketStatus.completed,
        method: PaymentMethod.card,
        total: 266.80,
        cashier: 'M. López',
        lines: [
          CartLine(product: products[2], quantity: 4),
          CartLine(product: products[6], quantity: 1),
        ],
      ),
      PosTicket(
        id: 't03',
        folio: 'T-0039',
        time: '17:58',
        status: TicketStatus.cancelled,
        method: PaymentMethod.cash,
        total: 110.20,
        cashier: 'M. López',
        lines: [CartLine(product: products[9], quantity: 1)],
      ),
    ];
  }
}
