import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../pos/data/models/pos_models.dart';
import '../models/retail_models.dart';

abstract interface class RetailRepository {
  Future<List<FittingRoom>> listRooms({FittingRoomStatus? status, CancelToken? cancelToken});
  Future<FittingRoom> getRoom(String roomId);
  Future<FittingRoomSession> openSession(String roomId, {required String clientName});
  Future<FittingRoomSessionItem> addItem(
    String roomId, {
    required String productId,
    required int quantity,
  });
  Future<List<FittingRoomSessionItem>> listItems(String roomId);
  Future<void> removeItem(String roomId, String itemId);
  Future<CheckoutResult> checkout(
    String sessionId, {
    required List<String> returnedItemIds,
    required List<String> saleItemIds,
    required String idempotencyKey,
  });
  Future<RetailDraft> createDraft(String sessionId);
  Future<List<RetailDraft>> listDrafts({RetailDraftStatus? status, CancelToken? cancelToken});
  Future<RetailDraft> getDraft(String draftId);
  Future<void> consumeDraft(String draftId, {String? saleId, required String idempotencyKey});
  Future<RetailDraft> cancelDraft(String draftId);
  Future<List<PosProduct>> searchProducts(String query, {CancelToken? cancelToken});
  Future<PosProduct> getProduct(String productId);
}

class HttpRetailRepository implements RetailRepository {
  HttpRetailRepository(this._client);

  final DioClient _client;
  static const _base = '/api/v1/tenant/retail';

  @override
  Future<List<FittingRoom>> listRooms({FittingRoomStatus? status, CancelToken? cancelToken}) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_base/fitting-rooms',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
        },
        cancelToken: cancelToken,
      ),
    ),
    FittingRoom.fromJson,
  );

  @override
  Future<FittingRoom> getRoom(String roomId) async => FittingRoom.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>('$_base/fitting-rooms/$roomId'),
    ),
  );

  @override
  Future<FittingRoomSession> openSession(String roomId, {required String clientName}) async =>
      FittingRoomSession.fromJson(
        await _requestMap(
          () => _client.dio.post<Object?>(
            '$_base/fitting-rooms/$roomId/open-session',
            data: OpenFittingRoomSessionRequest(clientName: clientName).toJson(),
          ),
        ),
      );

  @override
  Future<FittingRoomSessionItem> addItem(
    String roomId, {
    required String productId,
    required int quantity,
  }) async => FittingRoomSessionItem.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_base/fitting-rooms/$roomId/items',
        data: AddFittingRoomItemRequest(productId: productId, quantity: quantity).toJson(),
      ),
    ),
  );

  @override
  Future<List<FittingRoomSessionItem>> listItems(String roomId) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>('$_base/fitting-rooms/$roomId/items'),
    ),
    FittingRoomSessionItem.fromJson,
  );

  @override
  Future<void> removeItem(String roomId, String itemId) => _requestVoid(
    () => _client.dio.delete<Object?>('$_base/fitting-rooms/$roomId/items/$itemId'),
  );

  @override
  Future<CheckoutResult> checkout(
    String sessionId, {
    required List<String> returnedItemIds,
    required List<String> saleItemIds,
    required String idempotencyKey,
  }) async => CheckoutResult.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_base/sessions/$sessionId/checkout',
        data: FittingRoomCheckoutRequest(
          returnedItemIds: returnedItemIds,
          saleItemIds: saleItemIds,
        ).toJson(),
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      ),
    ),
  );

  @override
  Future<RetailDraft> createDraft(String sessionId) async => RetailDraft.fromJson(
    await _requestMap(
      () => _client.dio.post<Object?>(
        '$_base/drafts',
        data: {'sessionId': sessionId},
      ),
    ),
  );

  @override
  Future<List<RetailDraft>> listDrafts({RetailDraftStatus? status, CancelToken? cancelToken}) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_base/drafts',
        queryParameters: {
          if (status != null) 'status': status.apiValue,
        },
        cancelToken: cancelToken,
      ),
    ),
    RetailDraft.fromJson,
  );

  @override
  Future<RetailDraft> getDraft(String draftId) async => RetailDraft.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>('$_base/drafts/$draftId'),
    ),
  );

  @override
  Future<void> consumeDraft(String draftId, {String? saleId, required String idempotencyKey}) => _requestVoid(
    () => _client.dio.post<Object?>(
      '$_base/drafts/$draftId/consume',
      data: {
        if (saleId != null) 'saleId': saleId,
      },
      options: Options(
        headers: {'Idempotency-Key': idempotencyKey},
      ),
    ),
  );

  @override
  Future<RetailDraft> cancelDraft(String draftId) async => RetailDraft.fromJson(
    await _requestMap(
      () => _client.dio.delete<Object?>('$_base/drafts/$draftId'),
    ),
  );

  @override
  Future<List<PosProduct>> searchProducts(String query, {CancelToken? cancelToken}) async => _objects(
    await _requestList(
      () => _client.dio.get<Object?>(
        '$_base/products/search',
        queryParameters: {
          'q': query.trim(),
          'limit': 50,
        },
        cancelToken: cancelToken,
      ),
    ),
    PosProduct.fromJson,
  );

  @override
  Future<PosProduct> getProduct(String productId) async => PosProduct.fromJson(
    await _requestMap(
      () => _client.dio.get<Object?>('$_base/products/$productId'),
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

  Future<void> _requestVoid(
    Future<Response<Object?>> Function() request,
  ) async {
    await _requestData(request);
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
