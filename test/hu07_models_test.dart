import 'package:flutter_test/flutter_test.dart';
import 'package:impulsa_suite_flutter/features/retail/data/models/retail_models.dart';

void main() {
  group('HU07 retail contracts', () {
    test('maps fitting room with its open session and items', () {
      final room = FittingRoom.fromJson({
        'id': 'room-1', 'branchId': 'branch-1', 'code': 'P-01', 'name': 'Probador 1', 'status': 'OCCUPIED',
        'activeSession': {'id': 'session-1', 'fittingRoomId': 'room-1', 'sellerId': 'seller-1', 'clientName': 'Ana', 'status': 'OPEN', 'openedAt': '2026-08-14T16:00:00.000Z', 'items': [
          {'id': 'item-1', 'sessionId': 'session-1', 'productId': 'product-1', 'quantity': 2, 'disposition': 'PENDING', 'product': {'id': 'product-1', 'name': 'Camisa M', 'sku': 'RET-1', 'salePrice': 299}},
        ]},
      });
      expect(room.status, FittingRoomStatus.occupied);
      expect(room.activeSession?.clientName, 'Ana');
      expect(room.activeSession?.items.single.quantity, 2);
      expect(room.activeSession?.items.single.disposition, FittingSessionItemDisposition.pending);
    });

    test('maps checkout with server priced POS draft', () {
      final result = CheckoutResult.fromJson({
        'session': {'id': 'session-1', 'fittingRoomId': 'room-1', 'sellerId': 'seller-1', 'clientName': 'Ana', 'status': 'CLOSED', 'openedAt': '2026-08-14T16:00:00.000Z', 'items': []},
        'roomId': 'room-1', 'roomStatus': 'AVAILABLE', 'draftId': 'draft-1', 'total': 299,
        'posCartDraft': [{'productId': 'product-1', 'quantity': 1, 'unitPrice': 299, 'sku': 'RET-1', 'name': 'Camisa M'}],
        'draft': {'draftId': 'draft-1', 'sessionId': 'session-1', 'clientName': 'Ana', 'sellerId': 'seller-1', 'sellerName': 'Vendedor', 'posCartDraft': [{'productId': 'product-1', 'quantity': 1, 'unitPrice': 299, 'sku': 'RET-1', 'name': 'Camisa M'}], 'total': 299, 'status': 'PENDING', 'createdAt': '2026-08-14T16:00:00.000Z', 'branchId': 'branch-1'},
        'message': 'Sesión liquidada',
      });
      expect(result.session.status, FittingRoomSessionStatus.closed);
      expect(result.roomStatus, FittingRoomStatus.available);
      expect(result.draft?.status, RetailDraftStatus.pending);
      expect(result.posCartDraft.single.unitPrice, 299);
    });

    test('serializes stable API state values', () {
      expect(FittingRoomStatus.needsReview.apiValue, 'NEEDS_REVIEW');
      expect(FittingSessionItemDisposition.sentToPos.apiValue, 'SENT_TO_POS');
      expect(RetailDraftStatus.cancelled.apiValue, 'CANCELLED');
      expect(
        const FittingRoomCheckoutRequest(
          returnedItemIds: ['returned'],
          saleItemIds: ['sale'],
        ).toJson(),
        {'returnedItemIds': ['returned'], 'saleItemIds': ['sale']},
      );
    });
  });
}
