import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/features/restaurant_floor/data/models/restaurant_models.dart';
import 'package:impulsa_suite_flutter/features/waiter/data/models/waiter_models.dart';

void main() {
  group('HU06 restaurant contracts', () {
    test('maps a table and its real open session', () {
      final table = RestaurantTable.fromJson({
        'id': 'table-1',
        'branchId': 'branch-1',
        'areaId': 'area-1',
        'number': 4,
        'name': 'Mesa 4',
        'capacity': 6,
        'status': 'OCCUPIED',
        'area': {'id': 'area-1', 'name': 'Terraza', 'code': 'TERRAZA'},
        'sessions': [
          {
            'id': 'session-1',
            'branchId': 'branch-1',
            'tableId': 'table-1',
            'waiterUserId': 'waiter-1',
            'status': 'OPEN',
            'dinerCount': 3,
            'openedAt': '2026-08-03T18:00:00.000Z',
            'waiterUser': {
              'id': 'waiter-1',
              'fullName': 'Mesero Real',
              'email': 'waiter@example.com',
            },
          },
        ],
      });

      expect(table.status, RestaurantTableStatus.occupied);
      expect(table.area?.name, 'Terraza');
      expect(table.activeSession?.dinerCount, 3);
      expect(table.waiterName, 'Mesero Real');
    });

    test('maps kitchen order, item statuses and backend totals', () {
      final order = KitchenOrder.fromJson({
        'id': 'order-1',
        'branchId': 'branch-1',
        'tableSessionId': 'session-1',
        'waiterUserId': 'waiter-1',
        'folio': 'CMD-REAL-001',
        'status': 'IN_PREPARATION',
        'createdAt': '2026-08-03T18:00:00.000Z',
        'updatedAt': '2026-08-03T18:05:00.000Z',
        'tableSession': {
          'id': 'session-1',
          'branchId': 'branch-1',
          'tableId': 'table-1',
          'waiterUserId': 'waiter-1',
          'status': 'OPEN',
          'dinerCount': 2,
          'table': {
            'id': 'table-1',
            'number': 2,
            'name': 'Mesa 2',
            'capacity': 4,
            'status': 'OCCUPIED',
          },
        },
        'items': [
          {
            'id': 'item-1',
            'productId': 'product-1',
            'quantity': 2,
            'unitPrice': 85.5,
            'lineTotal': 171,
            'status': 'READY',
            'product': {
              'id': 'product-1',
              'name': 'Platillo real',
              'sku': 'PLAT-1',
            },
          },
        ],
      });

      expect(order.status, KitchenOrderStatus.inPreparation);
      expect(order.items.single.status, KitchenItemStatus.ready);
      expect(order.items.single.productName, 'Platillo real');
      expect(order.total, 171);
      expect(order.tableLabel, 'Mesa 2');
    });

    test('maps menu stock returned by restaurant product alias', () {
      final product = MenuProduct.fromJson({
        'id': 'product-1',
        'name': 'Producto real',
        'sku': 'SKU-1',
        'salePrice': 99.9,
        'unitName': 'pieza',
        'category': {'id': 'category-1', 'name': 'Cocina'},
        'stockOnHand': 12,
        'availableStock': 9,
        'imageUrl': null,
      });

      expect(product.price, 99.9);
      expect(product.category, 'Cocina');
      expect(product.availableStock, 9);
      expect(product.available, isTrue);
    });

    test('serializes session and checkout without branch headers or ids', () {
      const session = OpenTableSessionRequest(
        dinerCount: 3,
        customerName: 'Mesa cumpleaños',
      );
      const checkout = RestaurantCheckoutRequest(
        cashShiftId: 'shift-1',
        paymentMethod: RestaurantPaymentMethod.cash,
        cashReceived: 500,
        nextTableStatus: RestaurantTableStatus.dirty,
      );

      expect(session.toJson(), isNot(contains('waiterUserId')));
      expect(session.toJson(), isNot(contains('branchId')));
      expect(checkout.toJson(), containsPair('paymentMethod', 'CASH'));
      expect(checkout.toJson(), containsPair('nextTableStatus', 'DIRTY'));
      expect(checkout.toJson(), isNot(contains('branchId')));
    });

    test('maps equal split values calculated by backend', () {
      final result = SplitBillResult.fromJson({
        'mode': 'EQUAL',
        'tableId': 'table-1',
        'sessionId': 'session-1',
        'grandTotal': 100,
        'parts': [
          {'part': 1, 'amount': 33.33},
          {'part': 2, 'amount': 33.33},
          {'part': 3, 'amount': 33.34},
        ],
        'items': [],
      });

      expect(result.parts.length, 3);
      expect(result.parts.last.amount, 33.34);
      expect(result.grandTotal, 100);
    });
  });
}
