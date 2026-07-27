import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/features/pos/data/models/pos_models.dart';

void main() {
  group('HU04 POS contracts', () {
    test('maps a product search response with branch stock', () {
      final product = PosProduct.fromJson({
        'id': 'product-1',
        'name': 'Agua',
        'sku': 'AGUA-1',
        'barcode': '750000000001',
        'salePrice': 18,
        'unitName': 'pieza',
        'category': {'id': 'category-1', 'name': 'Bebidas'},
        'stockOnHand': 12,
        'availableStock': 10,
        'imageUrl': null,
      });

      expect(product.id, 'product-1');
      expect(product.salePrice, 18);
      expect(product.category, 'Bebidas');
      expect(product.availableStock, 10);
    });

    test('keeps the card intent from a mixed sale pending', () {
      final sale = PosSale.fromJson({
        'id': 'sale-1',
        'branchId': 'branch-1',
        'cashShiftId': 'shift-1',
        'cashierId': 'cashier-1',
        'folio': 'VTA-DEMO-ABC123',
        'subtotal': 100,
        'discountAmount': 0,
        'total': 100,
        'status': 'COMPLETED',
        'paymentMethod': 'MIXED',
        'paymentStatus': 'PENDING',
        'cashReceived': 40,
        'items': const [],
        'payments': [
          {
            'id': 'cash-payment',
            'paymentMethod': 'CASH',
            'amount': 40,
            'status': 'COMPLETED',
          },
          {
            'id': 'card-payment',
            'paymentMethod': 'CARD',
            'amount': 60,
            'status': 'PENDING',
            'gatewayProvider': 'STRIPE',
            'gatewayIntentId': 'pi_123',
          },
        ],
        'cardPaymentIntent': {
          'intentId': 'pi_123',
          'amount': 60,
          'currency': 'MXN',
          'status': 'PENDING',
          'gatewayProvider': 'STRIPE',
        },
        'createdAt': '2026-07-27T12:00:00.000Z',
      });

      expect(sale.paymentMethod, PaymentMethod.mixed);
      expect(sale.paymentStatus, PaymentStatus.pending);
      expect(sale.pendingCardPayment?.amount, 60);
      expect(sale.cardPaymentIntent?.intentId, 'pi_123');
    });

    test('maps a shift summary without inventing missing totals', () {
      final result = CashShiftSummary.fromJson({
        'shift': {
          'id': 'shift-1',
          'branchId': 'branch-1',
          'cashierId': 'cashier-1',
          'status': 'OPEN',
          'openingAmount': 500,
          'openedAt': '2026-07-27T10:00:00.000Z',
        },
        'summary': {
          'salesCount': 3,
          'totalSales': 250,
          'totalCash': 150,
          'totalCard': 100,
          'difference': null,
        },
        'cashMovements': [
          {
            'type': 'OPENING_FLOAT',
            'amount': 500,
            'notes': 'Fondo',
            'createdAt': '2026-07-27T10:00:00.000Z',
          },
        ],
      });

      expect(result.shift.isOpen, isTrue);
      expect(result.salesCount, 3);
      expect(result.totalCash, 150);
      expect(result.difference, isNull);
      expect(result.cashMovements.single.type, 'OPENING_FLOAT');
    });
  });
}
