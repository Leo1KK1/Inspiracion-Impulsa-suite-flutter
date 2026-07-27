import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/features/inventory/data/models/inventory_models.dart';
import 'package:impulsa_suite_flutter/features/purchasing/data/models/purchasing_models.dart';

void main() {
  test(
    'InventoryItem respeta el semáforo y el stock disponible del backend',
    () {
      final item = InventoryItem.fromJson({
        'id': 'inv-1',
        'branchId': 'branch-1',
        'productId': 'product-1',
        'stockOnHand': 2,
        'reservedStock': 1,
        'availableStock': 1,
        'minStock': 5,
        'alertLevel': 'ORANGE',
        'product': {
          'name': 'Producto',
          'sku': 'SKU-1',
          'salePrice': 20,
          'status': 'ACTIVE',
        },
      });

      expect(item.isLowStock, isTrue);
      expect(item.availableStock, 1);
      expect(item.severity, StockSeverity.low);
    },
  );

  test('PurchaseOrder conserva pendientes y transiciones válidas', () {
    final order = PurchaseOrder.fromJson({
      'id': 'po-1',
      'folio': 'PO-001',
      'supplierId': 'supplier-1',
      'branchId': 'branch-1',
      'status': 'PARTIALLY_RECEIVED',
      'subtotal': 100,
      'total': 100,
      'createdAt': '2026-07-27T12:00:00.000Z',
      'supplier': {'id': 'supplier-1', 'name': 'Proveedor'},
      'branch': {'id': 'branch-1', 'name': 'Centro', 'code': 'CENTRO'},
      'items': [
        {
          'id': 'line-1',
          'productId': 'product-1',
          'quantityOrdered': 10,
          'quantityReceived': 4,
          'unitCost': 10,
          'lineTotal': 100,
          'product': {'id': 'product-1', 'name': 'Producto', 'sku': 'SKU-1'},
        },
      ],
      'receipts': <Object?>[],
    });

    expect(order.status, PurchaseOrderStatus.partiallyReceived);
    expect(order.canReceive, isTrue);
    expect(order.canCancel, isFalse);
    expect(order.items.single.pending, 6);
  });
}
