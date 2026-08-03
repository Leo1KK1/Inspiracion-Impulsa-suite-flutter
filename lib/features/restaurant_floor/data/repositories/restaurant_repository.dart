import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../waiter/data/models/waiter_models.dart';
import '../models/restaurant_models.dart';

abstract interface class RestaurantRepository {
  Future<List<MenuProduct>> searchMenu(
    String query, {
    int limit = 50,
    CancelToken? cancelToken,
  });
  Future<MenuProduct> getProduct(String productId);
  Future<List<RestaurantTable>> getTables({
    RestaurantTableStatus? status,
    String? areaId,
    CancelToken? cancelToken,
  });
  Future<RestaurantTable> getTable(String tableId);
  Future<TableSession> openSession(
    String tableId,
    OpenTableSessionRequest request,
  );
  Future<TableSession> assignWaiter(
    String tableId, {
    required String waiterUserId,
  });
  Future<KitchenOrder> createOrder(
    String tableId, {
    required List<WaiterOrderLine> items,
    String? notes,
  });
  Future<List<KitchenOrder>> getTableOrders(String tableId);
  Future<KitchenOrder> sendToKitchen(String orderId);
  Future<KitchenOrder> updateOrderStatus(
    String orderId,
    KitchenOrderStatus status,
  );
  Future<SplitBillResult> splitBillEqual(String tableId, {required int parts});
  Future<SplitBillResult> splitBillByItem(
    String tableId, {
    required List<SplitBillAssignment> assignments,
  });
  Future<RestaurantCheckoutResult> checkout(
    String tableId,
    RestaurantCheckoutRequest request,
  );
  Future<List<KitchenOrder>> getKitchenOrders({
    KitchenOrderStatus? status,
    String? tableSessionId,
    CancelToken? cancelToken,
  });
  Future<KitchenOrder> getKitchenOrder(String orderId);
  Future<KitchenOrder> updateKitchenItemStatus(
    String orderId,
    String itemId,
    KitchenItemStatus status,
  );
}

class HttpRestaurantRepository implements RestaurantRepository {
  HttpRestaurantRepository(this._client);

  final DioClient _client;

  static const _restaurant = '/api/v1/tenant/restaurant';
  static const _kitchen = '/api/v1/tenant/kitchen';

  @override
  Future<List<MenuProduct>> searchMenu(
    String query, {
    int limit = 50,
    CancelToken? cancelToken,
  }) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_restaurant/products/search',
        queryParameters: {
          if (query.trim().isNotEmpty) 'q': query.trim(),
          'limit': limit.clamp(1, 100),
        },
        cancelToken: cancelToken,
      ),
    ),
    MenuProduct.fromJson,
  );

  @override
  Future<MenuProduct> getProduct(String productId) async =>
      MenuProduct.fromJson(
        await _requestMap(
          () => _client.dio.get<Object?>('$_restaurant/products/$productId'),
        ),
      );

  @override
  Future<List<RestaurantTable>> getTables({
    RestaurantTableStatus? status,
    String? areaId,
    CancelToken? cancelToken,
  }) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_restaurant/tables',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          if (areaId?.isNotEmpty == true) 'areaId': areaId,
        },
        cancelToken: cancelToken,
      ),
    ),
    RestaurantTable.fromJson,
  );

  @override
  Future<RestaurantTable> getTable(String tableId) async =>
      RestaurantTable.fromJson(
        await _requestMap(
          () => _client.dio.get<Object?>('$_restaurant/tables/$tableId'),
        ),
      );

  @override
  Future<TableSession> openSession(
    String tableId,
    OpenTableSessionRequest request,
  ) async => TableSession.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_restaurant/tables/$tableId/open-session',
        data: request.toJson(),
      ),
    ),
  );

  @override
  Future<TableSession> assignWaiter(
    String tableId, {
    required String waiterUserId,
  }) async => TableSession.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_restaurant/tables/$tableId/assign-waiter',
        data: {'waiterUserId': waiterUserId},
      ),
    ),
  );

  @override
  Future<KitchenOrder> createOrder(
    String tableId, {
    required List<WaiterOrderLine> items,
    String? notes,
  }) async => KitchenOrder.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_restaurant/tables/$tableId/orders',
        data: {
          'items': items.map((item) => item.toJson()).toList(growable: false),
          if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
        },
      ),
    ),
  );

  @override
  Future<List<KitchenOrder>> getTableOrders(String tableId) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>('$_restaurant/tables/$tableId/orders'),
    ),
    KitchenOrder.fromJson,
  );

  @override
  Future<KitchenOrder> sendToKitchen(String orderId) async =>
      KitchenOrder.fromJson(
        await _requestMap(
          () => _client.dio.post<Object?>(
            '$_restaurant/orders/$orderId/send-to-kitchen',
          ),
        ),
      );

  @override
  Future<KitchenOrder> updateOrderStatus(
    String orderId,
    KitchenOrderStatus status,
  ) async => KitchenOrder.fromJson(
    await _requestMap(
      () => _client.dio.patch<Object?>(
        '$_restaurant/orders/$orderId/status',
        data: {'status': status.apiValue},
      ),
    ),
  );

  @override
  Future<SplitBillResult> splitBillEqual(
    String tableId, {
    required int parts,
  }) async => SplitBillResult.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_restaurant/tables/$tableId/split-bill',
        data: {'mode': 'EQUAL', 'parts': parts},
      ),
    ),
  );

  @override
  Future<SplitBillResult> splitBillByItem(
    String tableId, {
    required List<SplitBillAssignment> assignments,
  }) async => SplitBillResult.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_restaurant/tables/$tableId/split-bill',
        data: {
          'mode': 'BY_ITEM',
          'assignments': assignments
              .map((assignment) => assignment.toJson())
              .toList(growable: false),
        },
      ),
    ),
  );

  @override
  Future<RestaurantCheckoutResult> checkout(
    String tableId,
    RestaurantCheckoutRequest request,
  ) async => RestaurantCheckoutResult.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_restaurant/tables/$tableId/checkout',
        data: request.toJson(),
      ),
    ),
  );

  @override
  Future<List<KitchenOrder>> getKitchenOrders({
    KitchenOrderStatus? status,
    String? tableSessionId,
    CancelToken? cancelToken,
  }) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_kitchen/orders',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
          if (tableSessionId?.isNotEmpty == true)
            'tableSessionId': tableSessionId,
        },
        cancelToken: cancelToken,
      ),
    ),
    KitchenOrder.fromJson,
  );

  @override
  Future<KitchenOrder> getKitchenOrder(String orderId) async =>
      KitchenOrder.fromJson(
        await _requestMap(
          () => _client.dio.get<Object?>('$_kitchen/orders/$orderId'),
        ),
      );

  @override
  Future<KitchenOrder> updateKitchenItemStatus(
    String orderId,
    String itemId,
    KitchenItemStatus status,
  ) async => KitchenOrder.fromJson(
    await _requestMap(
      () => _client.dio.patch<Object?>(
        '$_kitchen/orders/$orderId/items/$itemId/status',
        data: {'status': status.apiValue},
      ),
    ),
  );

  Future<Map<String, Object?>> _requestMap(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _requestData(request);
    if (data is! Map) throw _invalidResponse;
    return data.cast<String, Object?>();
  }

  Future<List<Object?>> _requestList(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _requestData(request);
    if (data is! List) throw _invalidResponse;
    return data.cast<Object?>();
  }

  Future<Object?> _requestData(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      final envelope = response.data;
      if (envelope is! Map || envelope['success'] != true) {
        throw _invalidResponse;
      }
      return envelope['data'];
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw ApiException.fromDio(error);
    }
  }

  static List<T> _objects<T>(
    List<Object?> values,
    T Function(Map<String, Object?> json) factory,
  ) => values
      .whereType<Map>()
      .map((value) => factory(value.cast<String, Object?>()))
      .toList(growable: false);

  static const _invalidResponse = ApiException(
    'El servidor devolvió una respuesta no válida.',
  );
}
