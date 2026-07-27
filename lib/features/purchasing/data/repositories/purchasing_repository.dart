import '../models/purchasing_models.dart';

abstract interface class PurchasingRepository {
  Future<List<PurchaseOrder>> getOrders();
  Future<List<Supplier>> getSuppliers();
  Future<List<PurchaseOrderLine>> getOrderLines(String orderId);
}

class MockPurchasingRepository implements PurchasingRepository {
  @override
  Future<List<PurchaseOrder>> getOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return [
      PurchaseOrder(
        id: 'po-001',
        folio: 'OC-2024-0041',
        supplier: 'Distribuidora Central S.A.',
        status: PurchaseOrderStatus.received,
        createdAt: DateTime(2024, 1, 18),
        expectedDate: DateTime(2024, 1, 22),
        items: 12,
        total: 18450,
        notes: 'Pedido semanal de bebidas y alimentos',
        createdBy: 'M. López',
      ),
      PurchaseOrder(
        id: 'po-002',
        folio: 'OC-2024-0042',
        supplier: 'Bebidas del Norte',
        status: PurchaseOrderStatus.sent,
        createdAt: DateTime(2024, 1, 20),
        expectedDate: DateTime(2024, 1, 25),
        items: 6,
        total: 9820.50,
        notes: 'Restock urgente de refrescos',
        createdBy: 'M. López',
      ),
      PurchaseOrder(
        id: 'po-003',
        folio: 'OC-2024-0043',
        supplier: 'Abarrotes Hernández',
        status: PurchaseOrderStatus.approved,
        createdAt: DateTime(2024, 1, 21),
        expectedDate: DateTime(2024, 1, 28),
        items: 20,
        total: 34120.75,
        notes: 'Pedido quincenal de abarrotes',
        createdBy: 'C. Ruiz',
      ),
      PurchaseOrder(
        id: 'po-004',
        folio: 'OC-2024-0044',
        supplier: 'Distribuidora Central S.A.',
        status: PurchaseOrderStatus.partial,
        createdAt: DateTime(2024, 1, 22),
        expectedDate: DateTime(2024, 1, 26),
        items: 8,
        total: 12300,
        notes: 'Recepción parcial pendiente',
        createdBy: 'M. López',
      ),
      PurchaseOrder(
        id: 'po-005',
        folio: 'OC-2024-0045',
        supplier: 'Empaques y Desechables MX',
        status: PurchaseOrderStatus.pending,
        createdAt: DateTime(2024, 1, 23),
        expectedDate: DateTime(2024, 1, 30),
        items: 5,
        total: 6750.20,
        notes: 'Desechables para el mes',
        createdBy: 'C. Ruiz',
      ),
    ];
  }

  @override
  Future<List<Supplier>> getSuppliers() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [
      Supplier(
        id: 's-001',
        code: 'DIST-001',
        name: 'Distribuidora Central S.A.',
        rfc: 'DCS870412GJ7',
        contact: 'Carlos Mendoza',
        email: 'c.mendoza@distcentral.mx',
        phone: '55 1234 5678',
        city: 'CDMX',
        categories: ['Bebidas', 'Alimentos', 'Abarrotes'],
        paymentTerms: '30 días neto',
        totalOrders: 84,
        active: true,
      ),
      Supplier(
        id: 's-002',
        code: 'BDN-002',
        name: 'Bebidas del Norte',
        rfc: 'BDN920611HJK',
        contact: 'Ana Flores',
        email: 'ana.flores@bebidasnorte.com',
        phone: '81 9876 5432',
        city: 'Monterrey',
        categories: ['Bebidas', 'Alcohólicas'],
        paymentTerms: '15 días neto',
        totalOrders: 47,
        active: true,
      ),
      Supplier(
        id: 's-003',
        code: 'AHZ-003',
        name: 'Abarrotes Hernández',
        rfc: 'AHE810203MNO',
        contact: 'Jesús Hernández',
        email: 'pedidos@abarroteshernandez.mx',
        phone: '55 5555 1234',
        city: 'CDMX',
        categories: ['Alimentos', 'Abarrotes', 'Lácteos'],
        paymentTerms: 'Contado',
        totalOrders: 126,
        active: true,
      ),
      Supplier(
        id: 's-004',
        code: 'EDM-004',
        name: 'Empaques y Desechables MX',
        rfc: 'EDM960718PQR',
        contact: 'Laura Soto',
        email: 'ventas@empaquesmx.com.mx',
        phone: '55 4321 8765',
        city: 'Naucalpan',
        categories: ['Desechables', 'Empaques'],
        paymentTerms: '30 días neto',
        totalOrders: 31,
        active: true,
      ),
      Supplier(
        id: 's-005',
        code: 'CPM-005',
        name: 'Carnes Premium MX',
        rfc: 'CPM011129STU',
        contact: 'Roberto Garza',
        email: 'r.garza@carnespremium.mx',
        phone: '55 2222 3333',
        city: 'CDMX',
        categories: ['Alimentos', 'Carnes'],
        paymentTerms: '8 días neto',
        totalOrders: 19,
        active: false,
      ),
    ];
  }

  @override
  Future<List<PurchaseOrderLine>> getOrderLines(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [
      PurchaseOrderLine(
        sku: 'BEB-001',
        name: 'Coca-Cola 600ml',
        unit: 'pieza',
        ordered: 120,
        received: 60,
        cost: 8.50,
        stockBefore: 20,
        minimum: 50,
      ),
      PurchaseOrderLine(
        sku: 'DES-002',
        name: 'Vasos desechables 16oz',
        unit: 'paquete',
        ordered: 50,
        received: 50,
        cost: 95,
        stockBefore: 22,
        minimum: 40,
      ),
      PurchaseOrderLine(
        sku: 'ALI-003',
        name: 'Pollo entero 1.5kg',
        unit: 'kg',
        ordered: 30,
        received: 0,
        cost: 145,
        stockBefore: 18,
        minimum: 25,
      ),
    ];
  }
}
